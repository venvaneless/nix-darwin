# darwin/system-commands/backups/obsidian-library.nix
#
# =====================================================================
# SYSTEM COMMAND: OBSIDIAN LIBRARY
#
# Installs `obsidian-library`, an interactive manager for the permanent
# Obsidian plugin and theme library. The command only uses GitHub release
# assets; it never clones a repository.
# =====================================================================

{ pkgs, ... }:

let
  # ---- Obsidian library manager
  # Python is included with this command. GitHub CLI and fzf are already
  # installed globally, so their existing store paths are used directly.
  obsidianLibrary = pkgs.writeShellApplication {
    name = "obsidian-library";

    runtimeInputs = [
      pkgs.python3
    ];

    text = ''
      export OBSIDIAN_LIBRARY_GH="${pkgs.gh}/bin/gh"
      export OBSIDIAN_LIBRARY_FZF="${pkgs.fzf}/bin/fzf"

      exec python3 - "$@" <<'PY'
      #!/usr/bin/env python3
      #
      # Obsidian plugin and theme library manager.
      #
      # The manager intentionally has no third-party Python dependencies and
      # only downloads the release assets it is allowed to update.

      from __future__ import annotations

      import argparse
      import json
      import os
      import re
      import shutil
      import subprocess
      import sys
      import tempfile
      from dataclasses import dataclass
      from pathlib import Path
      from typing import Any


      DEFAULT_PLUGINS_DIR = Path(
          "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/"
          "data-backups/app-backups/obsidian/obsidian_extensions"
      )
      DEFAULT_THEMES_DIR = Path(
          "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/"
          "data-backups/app-backups/obsidian/obsidian_themes"
      )
      REPOSITORY_FILE = "repository-url.txt"
      MANIFEST_FILE = "manifest.json"
      GH_BIN = os.environ["OBSIDIAN_LIBRARY_GH"]
      FZF_BIN = os.environ["OBSIDIAN_LIBRARY_FZF"]


      @dataclass(frozen=True)
      class LibraryType:
          label: str
          root: Path
          payload_file: str
          optional_files: tuple[str, ...]


      @dataclass(frozen=True)
      class LibraryEntry:
          library_type: LibraryType
          path: Path
          repository: str
          local_version: str

          @property
          def label(self) -> str:
              return self.path.name


      @dataclass(frozen=True)
      class CheckResult:
          entry: LibraryEntry
          status: str
          remote_version: str | None = None
          message: str = ""
          release: dict[str, Any] | None = None


      def print_heading(text: str) -> None:
          print()
          print(f"== {text} ==")


      def fail(message: str) -> None:
          print(f"Error: {message}", file=sys.stderr)


      def run(command: list[str], *, text: bool = True) -> subprocess.CompletedProcess[Any]:
          return subprocess.run(command, capture_output=True, text=text, check=False)


      def gh_json(endpoint: str) -> dict[str, Any]:
          completed = run([GH_BIN, "api", endpoint])
          if completed.returncode != 0:
              detail = completed.stderr.strip() or completed.stdout.strip()
              raise RuntimeError(detail or f"GitHub request failed: {endpoint}")

          try:
              response = json.loads(completed.stdout)
          except json.JSONDecodeError as error:
              raise RuntimeError(f"GitHub returned invalid JSON for {endpoint}: {error}") from error

          if not isinstance(response, dict):
              raise RuntimeError(f"GitHub returned an unexpected response for {endpoint}")

          return response


      def github_repository(repository_file: Path) -> str:
          try:
              contents = repository_file.read_text(encoding="utf-8")
          except OSError as error:
              raise RuntimeError(f"cannot read {REPOSITORY_FILE}: {error}") from error

          match = re.search(r"github[.]com[/:]([^/\\s]+)/([^/\\s#]+)", contents)
          if match is None:
              raise RuntimeError(f"{REPOSITORY_FILE} does not contain a GitHub repository URL")

          owner, repository = match.groups()
          repository = repository.removesuffix(".git").rstrip("/")
          if not owner or not repository:
              raise RuntimeError(f"{REPOSITORY_FILE} contains an invalid GitHub repository URL")

          return f"{owner}/{repository}"


      def manifest_version(manifest_file: Path) -> str:
          try:
              manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError) as error:
              raise RuntimeError(f"cannot read valid {MANIFEST_FILE}: {error}") from error

          version = manifest.get("version")
          if not isinstance(version, str) or not version.strip():
              raise RuntimeError(f"{MANIFEST_FILE} has no usable version")

          return version.strip()


      def library_entries(library_type: LibraryType) -> list[LibraryEntry]:
          if not library_type.root.is_dir():
              raise RuntimeError(f"library directory does not exist: {library_type.root}")

          entries: list[LibraryEntry] = []
          for child in sorted(library_type.root.iterdir(), key=lambda path: path.name.casefold()):
              if child.name.startswith(".") or child.is_symlink() or not child.is_dir():
                  continue

              try:
                  repository = github_repository(child / REPOSITORY_FILE)
                  local_version = manifest_version(child / MANIFEST_FILE)
              except RuntimeError as error:
                  fail(f"Skipping {library_type.label.lower()} '{child.name}': {error}")
                  continue

              entries.append(LibraryEntry(library_type, child, repository, local_version))

          return entries


      def latest_release(repository: str, cache: dict[str, dict[str, Any] | Exception]) -> dict[str, Any]:
          cached = cache.get(repository)
          if isinstance(cached, Exception):
              raise cached
          if isinstance(cached, dict):
              return cached

          try:
              release = gh_json(f"repos/{repository}/releases/latest")
          except RuntimeError as error:
              cache[repository] = error
              raise

          cache[repository] = release
          return release


      def release_assets(release: dict[str, Any]) -> dict[str, dict[str, Any]]:
          assets = release.get("assets")
          if not isinstance(assets, list):
              return {}

          return {
              asset["name"]: asset
              for asset in assets
              if isinstance(asset, dict)
              and isinstance(asset.get("name"), str)
              and isinstance(asset.get("id"), int)
          }


      def download_asset(repository: str, asset: dict[str, Any], destination: Path) -> None:
          asset_id = asset.get("id")
          if not isinstance(asset_id, int):
              raise RuntimeError("release asset has no usable GitHub asset ID")

          completed = run(
              [
                  GH_BIN,
                  "api",
                  "-H",
                  "Accept: application/octet-stream",
                  f"repos/{repository}/releases/assets/{asset_id}",
              ],
              text=False,
          )
          if completed.returncode != 0:
              detail = completed.stderr.decode("utf-8", errors="replace").strip()
              raise RuntimeError(detail or f"could not download release asset {asset.get('name')}")

          destination.write_bytes(completed.stdout)


      def release_manifest(
          entry: LibraryEntry,
          release: dict[str, Any],
          cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> tuple[str, Path]:
          tag_name = release.get("tag_name")
          if not isinstance(tag_name, str) or not tag_name:
              raise RuntimeError("latest release has no usable tag name")

          cache_key = (entry.repository, tag_name)
          cached = cache.get(cache_key)
          if cached is not None:
              return cached

          manifest_asset = release_assets(release).get(MANIFEST_FILE)
          if manifest_asset is None:
              raise RuntimeError("latest release does not include manifest.json")

          cache_directory = Path(tempfile.mkdtemp(prefix="obsidian-library-manifest-"))
          cached_manifest = cache_directory / MANIFEST_FILE
          try:
              download_asset(entry.repository, manifest_asset, cached_manifest)
              version = manifest_version(cached_manifest)
          except Exception:
              shutil.rmtree(cache_directory, ignore_errors=True)
              raise

          cache[cache_key] = (version, cached_manifest)
          return cache[cache_key]


      def compare_versions(local_version: str, remote_version: str) -> int | None:
          if local_version == remote_version:
              return 0

          def parse(version: str) -> tuple[tuple[int, ...], bool] | None:
              match = re.fullmatch(r"v?(\\d+(?:[.]\\d+)*)(?:[-.]([0-9A-Za-z.-]+))?(?:[+].*)?", version)
              if match is None:
                  return None
              numbers = tuple(int(part) for part in match.group(1).split("."))
              return numbers, match.group(2) is None

          local = parse(local_version)
          remote = parse(remote_version)
          if local is None or remote is None:
              return None

          max_length = max(len(local[0]), len(remote[0]))
          local_numbers = local[0] + (0,) * (max_length - len(local[0]))
          remote_numbers = remote[0] + (0,) * (max_length - len(remote[0]))
          if local_numbers < remote_numbers:
              return -1
          if local_numbers > remote_numbers:
              return 1
          if local[1] == remote[1]:
              return 0
          return 1 if local[1] else -1


      def check_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> CheckResult:
          try:
              release = latest_release(entry.repository, release_cache)
              remote_version, _ = release_manifest(entry, release, manifest_cache)
          except RuntimeError as error:
              return CheckResult(entry, "UNAVAILABLE", message=str(error))

          comparison = compare_versions(entry.local_version, remote_version)
          if comparison == 0:
              return CheckResult(entry, "UP TO DATE", remote_version, release=release)
          if comparison == -1:
              return CheckResult(entry, "UPDATE AVAILABLE", remote_version, release=release)
          if comparison == 1:
              return CheckResult(entry, "LOCAL VERSION NEWER", remote_version, release=release)
          return CheckResult(entry, "VERSION DIFFERENT", remote_version, release=release)


      def show_checks(entries: list[LibraryEntry], release_cache: dict[str, dict[str, Any] | Exception], manifest_cache: dict[tuple[str, str], tuple[str, Path]]) -> list[CheckResult]:
          results: list[CheckResult] = []
          for entry in entries:
              result = check_entry(entry, release_cache, manifest_cache)
              results.append(result)
              remote = result.remote_version or "-"
              suffix = f" — {result.message}" if result.message else ""
              print(f"[{result.status}] {entry.library_type.label}: {entry.label} ({entry.local_version} -> {remote}){suffix}")
          return results


      def archive_status(entry: LibraryEntry) -> None:
          try:
              repository = gh_json(f"repos/{entry.repository}")
          except RuntimeError as error:
              print(f"[UNAVAILABLE] {entry.label} — {error}")
              return

          archived = repository.get("archived") is True
          status = "ARCHIVED" if archived else "ACTIVE"
          print(f"[{status}] {entry.library_type.label}: {entry.label} ({entry.repository})")


      def update_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> None:
          result = check_entry(entry, release_cache, manifest_cache)
          if result.status != "UPDATE AVAILABLE" or result.release is None:
              suffix = f": {result.message}" if result.message else ""
              print(f"[SKIP] {entry.label}: {result.status}{suffix}")
              return

          assets = release_assets(result.release)
          required_files = (MANIFEST_FILE, entry.library_type.payload_file)
          missing_files = [filename for filename in required_files if filename not in assets]
          if missing_files:
              print(f"[SKIP] {entry.label}: latest release is missing {', '.join(missing_files)}")
              return

          allowed_files = required_files + entry.library_type.optional_files
          with tempfile.TemporaryDirectory(prefix="obsidian-library-update-") as temporary_directory:
              temporary_path = Path(temporary_directory)
              downloaded: list[str] = []
              try:
                  for filename in allowed_files:
                      asset = assets.get(filename)
                      if asset is None:
                          continue
                      destination = temporary_path / filename
                      download_asset(entry.repository, asset, destination)
                      downloaded.append(filename)

                  downloaded_version = manifest_version(temporary_path / MANIFEST_FILE)
                  if downloaded_version != result.remote_version:
                      raise RuntimeError(
                          f"downloaded manifest version {downloaded_version} does not match checked release version {result.remote_version}"
                      )

                  for filename in downloaded:
                      source = temporary_path / filename
                      destination = entry.path / filename
                      staging = destination.with_name(f".{destination.name}.obsidian-library-new")
                      shutil.copyfile(source, staging)
                      os.replace(staging, destination)
              except (OSError, RuntimeError) as error:
                  print(f"[FAILED] {entry.label}: {error}")
                  return

          print(f"[UPDATED] {entry.label}: {entry.local_version} -> {result.remote_version} ({', '.join(downloaded)})")


      def remove_entry(entry: LibraryEntry) -> None:
          expected_root = entry.library_type.root.resolve()
          try:
              entry.path.resolve().relative_to(expected_root)
          except ValueError:
              print(f"[SKIP] {entry.label}: path is outside the configured library directory")
              return

          confirmation = input(f"Type REMOVE {entry.library_type.label} {entry.label} to move it to Trash: ")
          if confirmation != f"REMOVE {entry.library_type.label} {entry.label}":
              print(f"[SKIP] {entry.label}: removal was not confirmed")
              return

          script = f'tell application "Finder" to delete POSIX file {json.dumps(str(entry.path))}'
          completed = run(["/usr/bin/osascript", "-e", script])
          if completed.returncode != 0:
              detail = completed.stderr.strip() or completed.stdout.strip()
              print(f"[FAILED] {entry.label}: {detail or 'Finder could not move the folder to Trash'}")
              return

          print(f"[TRASHED] {entry.label}")


      def fzf_select(lines: list[str], prompt: str, header: str, *, multi: bool = False) -> list[str]:
          if not lines:
              return []

          command = [
              FZF_BIN,
              "--height=80%",
              "--reverse",
              f"--prompt={prompt}",
              f"--header={header}",
              "--no-sort",
          ]
          if multi:
              command.extend(["--multi", "--bind=tab:toggle+down"])

          completed = subprocess.run(
              command,
              input="\n".join(lines) + "\n",
              capture_output=True,
              text=True,
              check=False,
          )
          if completed.returncode != 0:
              return []

          return [line for line in completed.stdout.splitlines() if line]


      def choose_entries(library_type: LibraryType) -> list[LibraryEntry]:
          try:
              entries = library_entries(library_type)
          except RuntimeError as error:
              fail(str(error))
              return []

          if not entries:
              print(f"No valid {library_type.label.lower()} were found in {library_type.root}.")
              return []

          rows = [
              f"{entry.label}\t{entry.local_version}\t{entry.repository}"
              for entry in entries
          ]
          selected_rows = fzf_select(
              rows,
              f"{library_type.label.lower()}> ",
              "TAB selects multiple entries; ENTER continues with the selected entries.",
              multi=True,
          )
          selected = set(selected_rows)
          return [entry for entry, row in zip(entries, rows, strict=True) if row in selected]


      def choose_action(library_type: LibraryType) -> str | None:
          actions = [
              "Check for updates",
              "Update",
              "Remove",
              "Check archived status",
              "Back",
          ]
          selection = fzf_select(actions, f"{library_type.label.lower()} action> ", "Choose what to do with the selected entries.")
          return selection[0] if selection else None


      def manage_type(
          library_type: LibraryType,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> None:
          while True:
              entries = choose_entries(library_type)
              if not entries:
                  return

              action = choose_action(library_type)
              if action is None or action == "Back":
                  return

              print_heading(action)
              if action == "Check for updates":
                  show_checks(entries, release_cache, manifest_cache)
              elif action == "Update":
                  for entry in entries:
                      update_entry(entry, release_cache, manifest_cache)
              elif action == "Remove":
                  for entry in entries:
                      remove_entry(entry)
              elif action == "Check archived status":
                  for entry in entries:
                      archive_status(entry)

              input("\nPress ENTER to return to the selection menu.")


      def all_entries(library_types: tuple[LibraryType, ...]) -> list[LibraryEntry]:
          entries: list[LibraryEntry] = []
          for library_type in library_types:
              try:
                  entries.extend(library_entries(library_type))
              except RuntimeError as error:
                  fail(str(error))
          return entries


      def main() -> int:
          parser = argparse.ArgumentParser(description="Manage the local Obsidian plugin and theme library.")
          parser.add_argument("--check-all", action="store_true", help="Check every valid plugin and theme without opening fzf.")
          arguments = parser.parse_args()

          library_types = (
              LibraryType(
                  "Plugins",
                  Path(os.environ.get("OBSIDIAN_LIBRARY_PLUGINS_DIR", DEFAULT_PLUGINS_DIR)),
                  "main.js",
                  ("styles.css", "README.md"),
              ),
              LibraryType(
                  "Themes",
                  Path(os.environ.get("OBSIDIAN_LIBRARY_THEMES_DIR", DEFAULT_THEMES_DIR)),
                  "theme.css",
                  ("README.md",),
              ),
          )
          release_cache: dict[str, dict[str, Any] | Exception] = {}
          manifest_cache: dict[tuple[str, str], tuple[str, Path]] = {}

          try:
              if arguments.check_all:
                  print_heading("Check all updates")
                  show_checks(all_entries(library_types), release_cache, manifest_cache)
                  return 0

              menu_items = ["Plugins", "Themes", "Check all updates", "Quit"]
              while True:
                  selection = fzf_select(menu_items, "obsidian-library> ", "Choose a library or check every installed item.")
                  choice = selection[0] if selection else "Quit"
                  if choice == "Plugins":
                      manage_type(library_types[0], release_cache, manifest_cache)
                  elif choice == "Themes":
                      manage_type(library_types[1], release_cache, manifest_cache)
                  elif choice == "Check all updates":
                      print_heading("Check all updates")
                      show_checks(all_entries(library_types), release_cache, manifest_cache)
                      input("\nPress ENTER to return to the main menu.")
                  else:
                      return 0
          finally:
              for _, cached_manifest in manifest_cache.values():
                  shutil.rmtree(cached_manifest.parent, ignore_errors=True)


      if __name__ == "__main__":
          raise SystemExit(main())
      PY
    '';
  };
in
{
  # ---- Obsidian library command
  # Makes the interactive library manager available as `obsidian-library`.
  environment.systemPackages = [
    obsidianLibrary
  ];
}
