#!/usr/bin/env python3
"""Back up Obsidian community plugins listed in sources.txt.

For each 'Folder:'/'Link:' pair this shallow-clones the plugin repository,
keeps only the files worth backing up, adds the published release assets,
and commits the result in batches.

Design notes, because the previous version stalled:

* The old script staged the whole ~3 GB tree into a single commit and push.
  Git then delta-compressed thousands of large binary blobs in one pack,
  which runs for hours, and GitHub refuses pushes over 2 GB regardless.
  Work is now pushed every BATCH_MB or BATCH_COUNT plugins.

* 'git ls-remote' was already called to test reachability. It also returns
  the HEAD commit, so recording it in .backup-state.json lets a run touch
  only the repositories that actually moved.

* A clone brings source trees, test suites, build configs and lockfiles,
  which measured at roughly 40% of the downloaded bytes. Only the files in
  KEEP_NAMES / KEEP_SUFFIXES are retained.

* main.js is a build artifact that most plugins never commit, so a clone
  alone does not produce a restorable plugin. Release assets are fetched
  separately.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path.cwd()
SOURCES = ROOT / "sources.txt"
FAILURE_FILE = ROOT / "unreachable-sources.txt"
STATE_FILE = ROOT / ".backup-state.json"
SKIPPED_FILE = ROOT / "skipped-files.txt"


def env_int(name: str, default: int) -> int:
    try:
        return int(os.environ.get(name, "") or default)
    except ValueError:
        return default


# GitHub hard-rejects any file above 100 MB, so this is a safety rail
# rather than a pruning policy.
MAX_FILE_BYTES = env_int("MAX_FILE_MB", 99) * 1024 * 1024
BATCH_BYTES = env_int("BATCH_MB", 400) * 1024 * 1024
BATCH_COUNT = env_int("BATCH_COUNT", 200)
CLONE_WORKERS = env_int("CLONE_WORKERS", 8)
LSREMOTE_WORKERS = env_int("LSREMOTE_WORKERS", 16)
FORCE_ALL = os.environ.get("FORCE_ALL", "").lower() == "true"

# ---------------------------------------------------------------------------
# What a plugin folder keeps
# ---------------------------------------------------------------------------

KEEP_NAMES = {
    "main.js", "manifest.json", "styles.css", "data.json", "versions.json",
    "license", "license.md", "license.txt", "licence", "licence.md",
    "licence.txt", "copying",
}

KEEP_SUFFIXES = {
    ".md", ".markdown",                                    # docs
    ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp",      # images
    ".ico", ".bmp", ".avif",
}

# Directories that never hold anything worth backing up.
SKIP_DIRS = {
    ".git", "node_modules", ".github", ".vscode", ".idea", "__pycache__",
    ".husky", ".yarn", "coverage", "test", "tests", "__tests__", "e2e",
}

# Release assets that are just the source tree in a wrapper.
ARCHIVE_SUFFIXES = (".zip", ".tar.gz", ".tgz", ".tar", ".gz", ".7z", ".rar")

# Files that must never be treated as plugin folders.
RESERVED = {
    ".git", ".github", "sources.txt", "unreachable-sources.txt",
    ".backup-state.json", "skipped-files.txt", "README.md", ".gitignore",
    ".gitattributes", "pruned-files.txt",
}

# A Git LFS pointer is a small text stub, not the real file.
LFS_MAGIC = b"version https://git-lfs.github.com/spec/v1"


def is_lfs_pointer(path) -> bool:
    try:
        if path.stat().st_size > 1024:
            return False
        with open(path, "rb") as handle:
            return handle.read(len(LFS_MAGIC)) == LFS_MAGIC
    except OSError:
        return False


USER_AGENT = "obsidian-plugin-backups/3.0 (+github-actions)"
API = "https://api.github.com"
TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""


# ---------------------------------------------------------------------------
# sources.txt
# ---------------------------------------------------------------------------

def parse_sources() -> list[tuple[str, str]]:
    if not SOURCES.is_file():
        raise SystemExit("sources.txt was not found")

    entries: list[tuple[str, str]] = []
    folder: str | None = None

    for raw_line in SOURCES.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        if line.startswith("Folder:"):
            folder = line.removeprefix("Folder:").strip()

        elif line.startswith("Link:") and folder:
            entries.append((folder, line.removeprefix("Link:").strip()))
            folder = None

    return entries


def validate_folder(folder: str) -> None:
    if not folder:
        raise ValueError("Empty folder name")
    if "/" in folder or "\0" in folder or folder in (".", ".."):
        raise ValueError(f"Unsafe folder name: {folder!r}")
    if folder in RESERVED:
        raise ValueError(f"Folder name collides with a repo file: {folder!r}")


def normalize_github_url(url: str) -> str:
    url = url.strip().rstrip("/")
    match = re.match(r"^https://github\.com/([^/]+)/([^/#?]+)", url,
                     re.IGNORECASE)
    if not match:
        raise ValueError(f"Not a GitHub repository URL: {url}")

    owner, repo = match.group(1), match.group(2)
    if repo.endswith(".git"):
        repo = repo[:-4]
    return f"{owner}/{repo}"


# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------

class RateLimited(RuntimeError):
    pass


def http_get(url: str, token: bool = False, as_json: bool = False):
    """GET a URL. Returns bytes, parsed JSON, or None on 404."""
    headers = {"User-Agent": USER_AGENT, "Accept": "*/*"}
    if token and TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    if as_json:
        headers["Accept"] = "application/vnd.github+json"

    last: Exception | None = None

    for attempt in range(1, 4):
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=60) as response:
                length = response.headers.get("Content-Length")
                if length and int(length) > MAX_FILE_BYTES:
                    return None
                body = response.read(MAX_FILE_BYTES + 1)
                if len(body) > MAX_FILE_BYTES:
                    return None
                return json.loads(body) if as_json else body

        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            if error.code in (403, 429):
                if error.headers.get("X-RateLimit-Remaining") == "0":
                    raise RateLimited("GitHub API rate limit reached")
                last = error
                time.sleep(2 ** attempt)
                continue
            if error.code >= 500:
                last = error
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"HTTP {error.code} for {url}") from error

        except Exception as error:
            last = error
            time.sleep(2 ** attempt)

    raise RuntimeError(f"could not fetch {url}: {last}")


def is_archive(name: str) -> bool:
    lowered = name.lower()
    return lowered.endswith(ARCHIVE_SUFFIXES)


def fetch_release(slug: str, destination: Path) -> tuple[list[str], bool]:
    """Download release assets. Returns (filenames, listing_was_complete).

    The API gives the full asset list but is rate limited. When that limit
    is hit we fall back to the three standard filenames, which resolve via
    a plain redirect with no API call, and report the listing as incomplete
    so the next run retries the plugin.
    """
    written: list[str] = []
    complete = True
    assets: list[tuple[str, str]] = []

    try:
        data = http_get(f"{API}/repos/{slug}/releases/latest",
                        token=True, as_json=True)
        if data:
            assets = [(a["name"], a["browser_download_url"])
                      for a in data.get("assets", [])
                      if not is_archive(a["name"])]
    except RateLimited:
        complete = False
    except Exception:
        complete = False

    if not assets:
        # Redirect route: needs no API call and has no rate limit.
        for name in ("manifest.json", "main.js", "styles.css"):
            assets.append(
                (name,
                 f"https://github.com/{slug}/releases/latest/download/{name}")
            )

    for name, url in assets:
        if "/" in name or "\0" in name:
            continue
        try:
            body = http_get(url)
        except Exception as error:
            print(f"::warning::{slug}: {name}: {error}")
            complete = False
            continue

        if body is not None:
            (destination / name).write_bytes(body)
            written.append(name)

    return written, complete


# ---------------------------------------------------------------------------
# git
# ---------------------------------------------------------------------------

def run(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    environment = dict(os.environ)
    # Never let git stop to ask for credentials; a deleted or private repo
    # must fail immediately rather than hang the job.
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["GIT_ASKPASS"] = ""
    environment["GCM_INTERACTIVE"] = "never"
    # Do not download Git LFS objects. Some plugin repos track large media
    # in LFS, and a failed or quota-exhausted LFS fetch fails the whole
    # clone. The pointer stubs left behind are filtered out below.
    environment["GIT_LFS_SKIP_SMUDGE"] = "1"
    return subprocess.run(args, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True,
                          env=environment, **kwargs)


def tidy_git_error(message: str) -> str:
    if any(s in message for s in ("could not read Username",
                                  "Authentication failed",
                                  "Repository not found")):
        return "repository not found (deleted, renamed, or made private)"
    return message


def remote_head(url: str) -> str:
    last = ""
    for attempt in range(1, 4):
        result = run(["git", "ls-remote", "--exit-code", url, "HEAD"])
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.split()[0]
        last = tidy_git_error(result.stderr.strip()) or "Repository is unreachable"
        if result.returncode == 2:
            break
        time.sleep(2 ** attempt)
    raise RuntimeError(last)


# ---------------------------------------------------------------------------
# filtering
# ---------------------------------------------------------------------------

def filter_tree(root: Path) -> tuple[int, list[str]]:
    """Delete everything not on the keep list. Returns (kept bytes, skipped)."""
    kept_bytes = 0
    oversized: list[str] = []

    for current, directories, files in os.walk(root, topdown=True):
        # Skipped directories must be DELETED, not merely skipped: pruning
        # them from os.walk means their files are never visited, so they
        # would survive into the backup untouched.
        for name in [d for d in directories if d in SKIP_DIRS]:
            shutil.rmtree(Path(current) / name, ignore_errors=True)
        directories[:] = [d for d in directories if d not in SKIP_DIRS]

        for name in files:
            path = Path(current) / name
            relative = path.relative_to(root)

            keep = (name.lower() in KEEP_NAMES
                    or path.suffix.lower() in KEEP_SUFFIXES)

            if keep:
                try:
                    size = path.stat().st_size
                except OSError:
                    path.unlink(missing_ok=True)
                    continue

                if size > MAX_FILE_BYTES:
                    oversized.append(f"{relative}\t{size // 1024 // 1024} MB")
                    path.unlink(missing_ok=True)
                elif is_lfs_pointer(path):
                    # A stub, not the file. Saving it would look like a
                    # valid image while being 130 bytes of text.
                    oversized.append(f"{relative}\tgit-lfs (not downloaded)")
                    path.unlink(missing_ok=True)
                else:
                    kept_bytes += size
                    continue
            else:
                path.unlink(missing_ok=True)

    # Drop directories left empty by the filter.
    for current, directories, files in os.walk(root, topdown=False):
        path = Path(current)
        if path != root and not any(path.iterdir()):
            path.rmdir()

    shutil.rmtree(root / ".git", ignore_errors=True)
    return kept_bytes, oversized


def back_up(folder: str, slug: str):
    """Clone, filter, add release assets, move into place."""
    destination = ROOT / folder
    url = f"https://github.com/{slug}.git"

    with tempfile.TemporaryDirectory() as temporary:
        checkout = Path(temporary) / "repo"

        result = run(["git", "clone", "--depth", "1", "--single-branch",
                      "--no-tags", url, str(checkout)])

        if result.returncode != 0:
            reason = tidy_git_error(result.stderr.strip()) or "git clone failed"

            # The clone failed, but release assets are served separately and
            # are the part that actually restores a plugin. Save those rather
            # than losing the plugin entirely.
            salvage = Path(temporary) / "release"
            salvage.mkdir(parents=True, exist_ok=True)
            released, _complete = fetch_release(slug, salvage)

            if not released:
                raise RuntimeError(reason)

            destination.mkdir(parents=True, exist_ok=True)
            for name in released:
                shutil.copy2(salvage / name, destination / name)

            size = sum((destination / n).stat().st_size for n in released
                       if (destination / n).is_file())
            return size, released, False, [], reason

        kept_bytes, oversized = filter_tree(checkout)
        released, complete = fetch_release(slug, checkout)

        size = kept_bytes + sum(
            (checkout / n).stat().st_size
            for n in released if (checkout / n).is_file()
        )

        # The existing backup survives until the new copy is ready.
        if destination.exists():
            if destination.is_symlink():
                destination.unlink()
            else:
                shutil.rmtree(destination)

        shutil.copytree(checkout, destination, symlinks=True)

    return size, released, complete, oversized, None


def commit_and_push(message: str) -> None:
    run(["git", "add", "-A"])
    if run(["git", "diff", "--cached", "--quiet"]).returncode == 0:
        return

    commit = run(["git", "commit", "--no-verify", "-m", message])
    if commit.returncode != 0:
        print(f"::warning::commit failed: {commit.stderr.strip()}")
        return

    for attempt in range(1, 4):
        push = run(["git", "push"])
        if push.returncode == 0:
            print(f"Pushed: {message}")
            return
        print(f"::warning::push attempt {attempt} failed: "
              f"{push.stderr.strip()}")
        run(["git", "pull", "--rebase", "--autostash"])
        time.sleep(5 * attempt)

    raise SystemExit("Could not push after 3 attempts")


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def load_state() -> dict:
    try:
        raw = json.loads(STATE_FILE.read_text("utf-8"))
    except Exception:
        return {"history_started": int(time.time()), "plugins": {}}

    if "plugins" not in raw:  # migrate the flat {folder: sha} format
        raw = {"history_started": int(time.time()),
               "plugins": {k: {"head": v} for k, v in raw.items()
                           if isinstance(v, str)}}
    raw.setdefault("history_started", int(time.time()))
    raw.setdefault("plugins", {})
    return raw


def main() -> int:
    entries = parse_sources()
    total = len(entries)
    print(f"Found {total} plugins in sources.txt.")
    if not total:
        return 0

    run(["git", "config", "user.name", "github-actions[bot]"])
    run(["git", "config", "user.email",
         "41898282+github-actions[bot]@users.noreply.github.com"])
    run(["git", "config", "core.bigFileThreshold", "16m"])

    state = load_state()
    plugins = state["plugins"]

    failures: list[tuple[str, str, str]] = []
    todo: list[tuple[str, str]] = []
    unchanged = 0

    print("\nChecking which plugin repositories changed...")

    def probe(item):
        folder, original_url = item
        try:
            validate_folder(folder)
            slug = normalize_github_url(original_url)
            return folder, original_url, slug, remote_head(
                f"https://github.com/{slug}.git"), None
        except Exception as error:
            return folder, original_url, None, None, str(error)

    with ThreadPoolExecutor(max_workers=LSREMOTE_WORKERS) as pool:
        probed = list(pool.map(probe, entries))

    for folder, original_url, slug, head, error in probed:
        if error is not None:
            print(f"UNREACHABLE: {folder}: {error}")
            failures.append((folder, original_url, error))
            continue

        known = plugins.get(folder, {})
        fresh = (known.get("head") == head
                 and known.get("assets_complete", False)
                 and (ROOT / folder).is_dir())

        if not FORCE_ALL and fresh:
            unchanged += 1
        else:
            todo.append((folder, slug))

    print(f"\nUnchanged:   {unchanged}")
    print(f"To update:   {len(todo)}")
    print(f"Unreachable: {len(failures)}")

    heads = {f: h for f, _u, _s, h, e in probed if e is None}
    skipped_all: list[tuple[str, str]] = []
    partials: list[tuple[str, str]] = []
    batch: list[str] = []
    batch_bytes = 0
    done = updated = 0

    def flush(reason: str) -> None:
        nonlocal batch, batch_bytes
        if not batch:
            return
        STATE_FILE.write_text(json.dumps(state, indent=1, sort_keys=True),
                              "utf-8")
        commit_and_push(
            f"Update plugin backups ({len(batch)} plugins, "
            f"{batch_bytes // (1024 * 1024)} MB) [{reason}]")
        batch, batch_bytes = [], 0

    def worker(item):
        folder, slug = item
        try:
            return (folder, slug) + back_up(folder, slug) + (None,)
        except Exception as error:
            return folder, slug, 0, [], False, [], None, str(error)

    with ThreadPoolExecutor(max_workers=CLONE_WORKERS) as pool:
        for folder, slug, size, released, complete, oversized, partial, \
                error in pool.map(worker, todo):
            done += 1

            if error is not None:
                print(f"[{done}/{len(todo)}] UNREACHABLE {folder}: {error}")
                failures.append((folder, f"https://github.com/{slug}", error))
                continue

            updated += 1
            plugins[folder] = {"head": heads.get(folder),
                               "assets_complete": complete and not partial}
            batch.append(folder)
            batch_bytes += size
            skipped_all += [(folder, s) for s in oversized]

            if partial:
                partials.append((folder, partial))
                flag = f" [PARTIAL: release files only - {partial[:80]}]"
            else:
                flag = ("" if complete
                        else " (asset list incomplete, retry next run)")
            print(f"[{done}/{len(todo)}] updated: {folder} {size // 1024} KB "
                  f"release={'+'.join(released) or 'NONE'}{flag}")

            if len(batch) >= BATCH_COUNT or batch_bytes >= BATCH_BYTES:
                flush(f"batch of {len(batch)}")

    if failures:
        lines = [f"Count: {len(failures)}", ""]
        for folder, url, error in sorted(failures):
            lines += [f"Folder: {folder}", f"Link: {url}",
                      f"Error: {error}", ""]
        FAILURE_FILE.write_text("\n".join(lines), "utf-8")
    elif FAILURE_FILE.exists():
        FAILURE_FILE.unlink()

    if skipped_all:
        lines = [f"# Files skipped for exceeding "
                 f"{MAX_FILE_BYTES // (1024 * 1024)} MB "
                 f"(GitHub rejects anything over 100 MB).", ""]
        lines += [f"{f}\t{s}" for f, s in sorted(skipped_all)]
        SKIPPED_FILE.write_text("\n".join(lines) + "\n", "utf-8")
    elif SKIPPED_FILE.exists():
        SKIPPED_FILE.unlink()

    flush("final")

    print(f"\nUpdated:     {updated}")
    print(f"Unchanged:   {unchanged}")
    print(f"Unreachable: {len(failures)}")
    print(f"Oversized/LFS skipped: {len(skipped_all)}")
    print(f"Partial (release only): {len(partials)}")
    for folder, reason in partials:
        print(f"  {folder}: {reason[:120]}")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(
                "### Plugin backup\n\n| Result | Count |\n|---|---:|\n"
                f"| Updated | {updated} |\n| Unchanged | {unchanged} |\n"
                f"| Unreachable | {len(failures)} |\n"
                f"| Oversized/LFS skipped | {len(skipped_all)} |\n"
                f"| Partial (release only) | {len(partials)} |\n\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
