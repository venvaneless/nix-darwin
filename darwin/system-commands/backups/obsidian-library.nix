# darwin/system-commands/backups/obsidian-library.nix
#
# =====================================================================
# SYSTEM COMMAND: OBSIDIAN LIBRARY
#
# Installs `obsidian-library`, an interactive manager for the permanent
# Obsidian plugin and theme library. Plugins only use strict GitHub release
# assets, while themes can also use files stored at a repository's root.
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

      # Keep standard input attached to the terminal for the interactive
      # menus; feeding Python through stdin makes every input() raise EOF.
      exec python3 <(${pkgs.coreutils}/bin/cat <<'PY'
      #!/usr/bin/env python3
      #
      # Obsidian plugin and theme library manager.
      #
      # The manager intentionally has no third-party Python dependencies and
      # only downloads the allowed release assets or theme repository files.

      from __future__ import annotations

      import argparse
      import hashlib
      import json
      import os
      import re
      import shutil
      import subprocess
      import sys
      import tempfile
      from dataclasses import dataclass
      from datetime import datetime
      from pathlib import Path
      from typing import Any


      DEFAULT_PLUGINS_DIR = Path(
          "/Volumes/SystemBackup/data-backups/app-backups/obsidian/obsidian_extensions/"
      )
      DEFAULT_THEMES_DIR = Path(
          "/Volumes/SystemBackup/data-backups/app-backups/obsidian/obsidian_themes/"
      )
      MANIFEST_FILE = "manifest.json"
      PLUGIN_URL_FIELD = "pluginUrl"
      THEME_URL_FIELD = "themeUrl"
      ABANDONED_FIELD = "abandoned"
      ARCHIVED_FIELD = "archived"
      README_FILE = "README.md"
      DEFAULT_DOWNLOADS_DIR = Path.home() / "Downloads"
      GH_BIN = os.environ["OBSIDIAN_LIBRARY_GH"]
      FZF_BIN = os.environ["OBSIDIAN_LIBRARY_FZF"]


      @dataclass(frozen=True)
      class LibraryType:
          label: str
          root: Path
          payload_file: str
          optional_files: tuple[str, ...]
          is_theme: bool = False


      @dataclass(frozen=True)
      class LibraryEntry:
          library_type: LibraryType
          path: Path
          identifier: str
          author: str
          description: str
          manifest_missing: bool
          repository: str | None
          local_version: str | None
          abandoned: bool
          archived: bool

          @property
          def label(self) -> str:
              return self.identifier

          @property
          def version_label(self) -> str:
              return self.local_version or "unversioned"

          @property
          def repository_url_label(self) -> str:
              return "yes" if self.repository is not None else "no"

          @property
          def manifest_missing_label(self) -> str:
              return "yes" if self.manifest_missing else "no"

          @property
          def repository_status_label(self) -> str:
              if self.abandoned:
                  return "abandoned"
              if self.archived:
                  return "archived"
              return ""


      @dataclass(frozen=True)
      class ThemeRemoteFile:
          source_name: str
          destination_name: str
          release_asset: dict[str, Any] | None = None
          repository_path: str | None = None


      @dataclass(frozen=True)
      class ThemeSource:
          location: str
          version_label: str | None
          files: tuple[ThemeRemoteFile, ...]


      @dataclass(frozen=True)
      class CheckResult:
          entry: LibraryEntry
          status: str
          remote_version: str | None = None
          message: str = ""
          release: dict[str, Any] | None = None
          theme_source: ThemeSource | None = None


      def print_heading(text: str) -> None:
          print()
          print(f"== {text} ==")


      def fail(message: str) -> None:
          print(f"Error: {message}", file=sys.stderr)


      def error_log_path() -> Path:
          return Path(os.environ.get("OBSIDIAN_LIBRARY_DOWNLOADS_DIR", DEFAULT_DOWNLOADS_DIR)) / "obsidian-library-errors.log"


      def report_error(message: str) -> None:
          fail(message)
          try:
              error_log_path().parent.mkdir(parents=True, exist_ok=True)
              with error_log_path().open("a", encoding="utf-8") as error_log:
                  error_log.write(f"Error: {message}\n")
          except OSError as error:
              fail(f"could not save the error log: {error}")


      def run(command: list[str], *, text: bool = True) -> subprocess.CompletedProcess[Any]:
          return subprocess.run(command, capture_output=True, text=text, check=False)


      def gh_value(endpoint: str) -> Any:
          completed = run([GH_BIN, "api", endpoint])
          if completed.returncode != 0:
              detail = completed.stderr.strip() or completed.stdout.strip()
              raise RuntimeError(detail or f"GitHub request failed: {endpoint}")

          try:
              response = json.loads(completed.stdout)
          except json.JSONDecodeError as error:
              raise RuntimeError(f"GitHub returned invalid JSON for {endpoint}: {error}") from error

          return response


      def gh_json(endpoint: str) -> dict[str, Any]:
          response = gh_value(endpoint)
          if not isinstance(response, dict):
              raise RuntimeError(f"GitHub returned an unexpected response for {endpoint}")
          return response


      def gh_list(endpoint: str) -> list[dict[str, Any]]:
          response = gh_value(endpoint)
          if not isinstance(response, list) or not all(isinstance(item, dict) for item in response):
              raise RuntimeError(f"GitHub returned an unexpected response for {endpoint}")
          return response


      def repository_field(library_type: LibraryType) -> str:
          return THEME_URL_FIELD if library_type.is_theme else PLUGIN_URL_FIELD


      def github_repository_from_url(value: Any) -> str | None:
          if not isinstance(value, str):
              return None
          match = re.fullmatch(
              r"\s*https?://(?:www[.])?github[.]com/([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9_.-]+)(?:[.]git)?/?\s*",
              value,
              flags=re.IGNORECASE,
          )
          if match is None:
              return None
          return f"{match.group(1)}/{match.group(2).removesuffix('.git')}"


      def manifest_repository(directory: Path, library_type: LibraryType) -> str | None:
          try:
              manifest = json.loads(manifest_file(directory).read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError):
              return None
          if not isinstance(manifest, dict):
              return None
          return github_repository_from_url(manifest.get(repository_field(library_type)))


      def manifest_status(directory: Path) -> tuple[bool, bool]:
          try:
              manifest = json.loads(manifest_file(directory).read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError):
              return False, False
          if not isinstance(manifest, dict):
              return False, False
          return manifest.get(ABANDONED_FIELD) == "yes", manifest.get(ARCHIVED_FIELD) == "yes"


      def write_manifest_fields(manifest_path: Path, fields: dict[str, str]) -> None:
          if manifest_path.is_symlink():
              raise RuntimeError(f"refusing to replace symlinked {MANIFEST_FILE}: {manifest_path}")
          try:
              manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError) as error:
              raise RuntimeError(f"cannot read valid {MANIFEST_FILE}: {error}") from error
          if not isinstance(manifest, dict):
              raise RuntimeError(f"{MANIFEST_FILE} does not contain an object")

          manifest.update(fields)
          staging = manifest_path.with_name(f".{manifest_path.name}.obsidian-library-new")
          try:
              staging.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
              os.replace(staging, manifest_path)
          except OSError:
              staging.unlink(missing_ok=True)
              raise


      def create_theme_manifest(manifest_path: Path, repository: str, theme_name: str) -> None:
          owner = repository.split("/", 1)[0]

          manifest = {
              "name": theme_name,
              "author": owner,
              "version": "0.0.0",
              "minAppVersion": "0.0.0",
              "themeUrl": f"https://github.com/{repository}",
              "generatedManifest": True,
          }

          manifest_path.write_text(
              json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
              encoding="utf-8",
          )


      def set_manifest_repository(manifest_path: Path, library_type: LibraryType, repository: str) -> None:
          write_manifest_fields(manifest_path, { repository_field(library_type): f"https://github.com/{repository}" })


      def mark_repository_status(entry: LibraryEntry, field: str) -> str:
          try:
              write_manifest_fields(manifest_file(entry.path), { field: "yes" })
          except RuntimeError as error:
              return f"; could not save {field}: {error}"
          return ""


      def manifest_file(directory: Path) -> Path:
          direct_file = directory / MANIFEST_FILE
          if direct_file.is_file():
              return direct_file
          return directory / "repo" / MANIFEST_FILE


      def manifest_metadata(directory: Path) -> tuple[str, str, str, str | None, bool]:
          source = manifest_file(directory)
          try:
              manifest = json.loads(source.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError):
              return directory.name, "", "", None, True

          if not isinstance(manifest, dict):
              return directory.name, "", "", None, True

          identifier = manifest.get("id")
          name = manifest.get("name")
          if isinstance(name, str) and name.strip():
              identifier = name.strip()
          elif isinstance(identifier, str) and identifier.strip():
              identifier = identifier.strip()
          else:
              identifier = directory.name

          author_value = manifest.get("author")
          author = author_value.strip() if isinstance(author_value, str) else ""
          if not author:
              author_url = manifest.get("authorUrl")
              author = author_url.strip() if isinstance(author_url, str) else ""
          if re.fullmatch(r"https?://[^\s]+", author, flags=re.IGNORECASE):
              author = re.sub(r"^https?://(?:www[.])?", "", author, flags=re.IGNORECASE)
              author = author.rstrip("/").rsplit("/", 1)[-1]
          author = re.sub(r"\s+", " ", author).strip()
          description_value = manifest.get("description")
          description = description_value.strip() if isinstance(description_value, str) else ""
          description = re.sub(r"\s+", " ", description).strip()

          return identifier, author, description, optional_manifest_version(source), False


      def manifest_version(manifest_file: Path) -> str:
          try:
              manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError) as error:
              raise RuntimeError(f"cannot read valid {MANIFEST_FILE}: {error}") from error

          version = manifest.get("version")
          if not isinstance(version, str) or not version.strip():
              raise RuntimeError(f"{MANIFEST_FILE} has no usable version")

          return version.strip()


      def optional_manifest_version(manifest_file: Path) -> str | None:
          if not manifest_file.is_file():
              return None

          try:
              return manifest_version(manifest_file)
          except RuntimeError:
              return None


      def library_entries(library_type: LibraryType) -> list[LibraryEntry]:
          if not library_type.root.is_dir():
              raise RuntimeError(f"library directory does not exist: {library_type.root}")

          entries: list[LibraryEntry] = []
          for child in sorted(library_type.root.iterdir(), key=lambda path: path.name.casefold()):
              if child.name.startswith(".") or child.is_symlink() or not child.is_dir():
                  continue

              identifier, author, description, local_version, manifest_missing = manifest_metadata(child)

              repository = manifest_repository(child, library_type)
              abandoned, archived = manifest_status(child)

              entries.append(
                  LibraryEntry(
                      library_type,
                      child,
                      identifier,
                      author,
                      description,
                      manifest_missing,
                      repository,
                      local_version,
                      abandoned,
                      archived,
                  )
              )

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


      def download_repository_file(repository: str, repository_path: str, destination: Path) -> None:
          completed = run(
              [
                  GH_BIN,
                  "api",
                  "-H",
                  "Accept: application/vnd.github.raw+json",
                  f"repos/{repository}/contents/{repository_path}",
              ],
              text=False,
          )
          if completed.returncode != 0:
              detail = completed.stderr.decode("utf-8", errors="replace").strip()
              raise RuntimeError(detail or f"could not download repository file {repository_path}")

          destination.write_bytes(completed.stdout)


      def download_repository_readme(repository: str, destination: Path) -> bool:
          # GitHub resolves README, README.md, and supported case variants.
          completed = run(
              [
                  GH_BIN,
                  "api",
                  "-H",
                  "Accept: application/vnd.github.raw+json",
                  f"repos/{repository}/readme",
              ],
              text=False,
          )
          if completed.returncode != 0 or not completed.stdout:
              return False

          destination.write_bytes(completed.stdout)
          return destination.is_file() and destination.stat().st_size > 0


      def is_nonempty_file(path: Path) -> bool:
          try:
              return path.is_file() and path.stat().st_size > 0
          except OSError:
              return False


      def manifest_is_valid(manifest_file: Path) -> bool:
          # Formatting is deliberately unrestricted: compact, tab-indented,
          # space-indented, CRLF, and trailing blank lines are all valid JSON.
          try:
              manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError):
              return False

          return isinstance(manifest, dict)


      def image_names(filenames: list[str]) -> list[str]:
          image_suffixes = {".avif", ".gif", ".jpeg", ".jpg", ".png", ".svg", ".webp"}
          return sorted(filename for filename in filenames if Path(filename).suffix.casefold() in image_suffixes)


      def theme_release_source(release: dict[str, Any]) -> ThemeSource | None:
          assets = release_assets(release)
          if "theme.css" not in assets and "obsidian.css" not in assets:
              return None

          files: list[ThemeRemoteFile] = []
          if "theme.css" in assets:
              files.append(ThemeRemoteFile("theme.css", "theme.css", release_asset=assets["theme.css"]))
          if "obsidian.css" in assets:
              destination_name = "obsidian.css" if "theme.css" in assets else "theme.css"
              files.append(ThemeRemoteFile("obsidian.css", destination_name, release_asset=assets["obsidian.css"]))
          if MANIFEST_FILE in assets:
              files.append(ThemeRemoteFile(MANIFEST_FILE, MANIFEST_FILE, release_asset=assets[MANIFEST_FILE]))
          if README_FILE in assets:
              files.append(ThemeRemoteFile(README_FILE, README_FILE, release_asset=assets[README_FILE]))

          for image_name in image_names(list(assets)):
              files.append(ThemeRemoteFile(image_name, image_name, release_asset=assets[image_name]))

          tag_name = release.get("tag_name")
          return ThemeSource(
              "latest release",
              tag_name if isinstance(tag_name, str) and tag_name else None,
              tuple(files),
          )


      def repository_root_files(
          repository: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> dict[str, dict[str, Any]]:
          cached = repository_contents_cache.get(repository)
          if isinstance(cached, Exception):
              raise cached
          if cached is None:
              try:
                  cached = gh_list(f"repos/{repository}/contents")
              except RuntimeError as error:
                  repository_contents_cache[repository] = error
                  raise
              repository_contents_cache[repository] = cached

          return {
              item["name"]: item
              for item in cached
              if item.get("type") == "file"
              and isinstance(item.get("name"), str)
              and isinstance(item.get("path"), str)
          }


      def theme_repository_source(
          repository: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> ThemeSource:
          files_by_name = repository_root_files(repository, repository_contents_cache)
          if "theme.css" not in files_by_name and "obsidian.css" not in files_by_name:
              raise RuntimeError("repository root has neither theme.css nor obsidian.css")

          def repository_file(filename: str, destination_name: str) -> ThemeRemoteFile:
              item = files_by_name[filename]
              return ThemeRemoteFile(filename, destination_name, repository_path=item["path"])

          files: list[ThemeRemoteFile] = []
          if "theme.css" in files_by_name:
              files.append(repository_file("theme.css", "theme.css"))
          if "obsidian.css" in files_by_name:
              destination_name = "obsidian.css" if "theme.css" in files_by_name else "theme.css"
              files.append(repository_file("obsidian.css", destination_name))
          if MANIFEST_FILE in files_by_name:
              files.append(repository_file(MANIFEST_FILE, MANIFEST_FILE))
          if README_FILE in files_by_name:
              files.append(repository_file(README_FILE, README_FILE))

          for image_name in image_names(list(files_by_name)):
              files.append(repository_file(image_name, image_name))

          return ThemeSource("repository root", None, tuple(files))


      def release_theme_source_with_repository_files(
          repository: str,
          source: ThemeSource,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> ThemeSource:
          # Keep release CSS authoritative, but add repository files that the
          # release did not include so README image links still work locally.
          try:
              files_by_name = repository_root_files(repository, repository_contents_cache)
          except RuntimeError:
              return source

          files = list(source.files)
          if MANIFEST_FILE in files_by_name and not any(remote_file.destination_name == MANIFEST_FILE for remote_file in files):
              files.append(ThemeRemoteFile(MANIFEST_FILE, MANIFEST_FILE, repository_path=files_by_name[MANIFEST_FILE]["path"]))
          if README_FILE in files_by_name and not any(remote_file.destination_name == README_FILE for remote_file in files):
              files.append(ThemeRemoteFile(README_FILE, README_FILE, repository_path=files_by_name[README_FILE]["path"]))

          downloaded_names = {remote_file.destination_name for remote_file in files}
          for image_name in image_names(list(files_by_name)):
              if image_name not in downloaded_names:
                  files.append(ThemeRemoteFile(image_name, image_name, repository_path=files_by_name[image_name]["path"]))

          return ThemeSource(source.location, source.version_label, tuple(files))


      def theme_source(
          repository: str,
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> ThemeSource:
          try:
              release = latest_release(repository, release_cache)
              source = theme_release_source(release)
              if source is not None:
                  return release_theme_source_with_repository_files(repository, source, repository_contents_cache)
          except RuntimeError:
              pass

          return theme_repository_source(repository, repository_contents_cache)


      def download_theme_file(repository: str, remote_file: ThemeRemoteFile, destination: Path) -> None:
          if remote_file.release_asset is not None:
              download_asset(repository, remote_file.release_asset, destination)
              return
          if remote_file.repository_path is not None:
              download_repository_file(repository, remote_file.repository_path, destination)
              return
          raise RuntimeError(f"theme source file {remote_file.source_name} is incomplete")


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


      def check_plugin_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> CheckResult:
          try:
              release = latest_release(entry.repository, release_cache)
              remote_version, _ = release_manifest(entry, release, manifest_cache)
          except RuntimeError as error:
              return CheckResult(entry, "UNAVAILABLE", message=str(error))

          if entry.local_version is None:
              return CheckResult(entry, "UNAVAILABLE", remote_version, "manifest has no version", release)

          comparison = compare_versions(entry.local_version, remote_version)
          if comparison == 0:
              return CheckResult(entry, "UP TO DATE", remote_version, release=release)
          if comparison == -1:
              return CheckResult(entry, "UPDATE AVAILABLE", remote_version, release=release)
          if comparison == 1:
              return CheckResult(entry, "LOCAL VERSION NEWER", remote_version, release=release)
          return CheckResult(entry, "VERSION DIFFERENT", remote_version, release=release)


      def theme_files_match(entry: LibraryEntry, source: ThemeSource) -> bool:
          with tempfile.TemporaryDirectory(prefix="obsidian-library-theme-check-") as temporary_directory:
              temporary_path = Path(temporary_directory)
              for remote_file in source.files:
                  local_file = entry.path / remote_file.destination_name
                  if not local_file.is_file():
                      return False

                  downloaded_file = temporary_path / remote_file.destination_name
                  download_theme_file(entry.repository, remote_file, downloaded_file)
                  if hashlib.sha256(local_file.read_bytes()).digest() != hashlib.sha256(downloaded_file.read_bytes()).digest():
                      return False

          return True


      def check_theme_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> CheckResult:
          try:
              source = theme_source(entry.repository, release_cache, repository_contents_cache)
              matches = theme_files_match(entry, source)
          except (OSError, RuntimeError) as error:
              return CheckResult(entry, "UNAVAILABLE", message=str(error))

          remote_version = source.version_label or source.location
          if matches:
              return CheckResult(entry, "UP TO DATE", remote_version, theme_source=source)
          return CheckResult(entry, "UPDATE AVAILABLE", remote_version, theme_source=source)


      def check_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> CheckResult:
          if entry.abandoned:
              return CheckResult(entry, "ABANDONED", message="manifest marks this repository as abandoned")
          if entry.repository is None:
              return CheckResult(
                  entry,
                  "REPOSITORY URL REQUIRED",
                  message=f"{repository_field(entry.library_type)} is missing or has no GitHub URL",
              )

          completed = run([GH_BIN, "api", f"repos/{entry.repository}"])
          if completed.returncode != 0:
              detail = completed.stderr.strip() or completed.stdout.strip()
              if re.search(r"(?:HTTP[ ]*)?404|not found", detail, flags=re.IGNORECASE):
                  suffix = mark_repository_status(entry, ABANDONED_FIELD)
                  return CheckResult(entry, "ABANDONED", message=f"GitHub returned 404; marked abandoned{suffix}")
              return CheckResult(entry, "UNAVAILABLE", message=detail or "could not check repository availability")

          try:
              repository_metadata = json.loads(completed.stdout)
          except json.JSONDecodeError as error:
              return CheckResult(entry, "UNAVAILABLE", message=f"GitHub returned invalid repository metadata: {error}")
          if not isinstance(repository_metadata, dict):
              return CheckResult(entry, "UNAVAILABLE", message="GitHub returned unexpected repository metadata")
          if repository_metadata.get("archived") is True:
              suffix = mark_repository_status(entry, ARCHIVED_FIELD)
              return CheckResult(entry, "ARCHIVED", message=f"GitHub marks this repository as archived{suffix}")

          if entry.library_type.is_theme:
              return check_theme_entry(entry, release_cache, repository_contents_cache)
          return check_plugin_entry(entry, release_cache, manifest_cache)


      def show_checks(
          entries: list[LibraryEntry],
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> list[CheckResult]:
          results: list[CheckResult] = []
          for entry in entries:
              result = check_entry(entry, release_cache, manifest_cache, repository_contents_cache)
              results.append(result)
              remote = result.remote_version or "-"
              suffix = f" — {result.message}" if result.message else ""
              print(f"[{result.status}] {entry.library_type.label}: {entry.label} ({entry.version_label} -> {remote}){suffix}")
              if result.status == "UNAVAILABLE":
                  report_error(f"Checking {entry.library_type.label.lower()} '{entry.label}' failed: {result.message}")
          return results


      def check_results(
          entries: list[LibraryEntry],
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> list[CheckResult]:
          return [
              check_entry(entry, release_cache, manifest_cache, repository_contents_cache)
              for entry in entries
          ]


      def offer_updates(
          results: list[CheckResult],
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          updateable = [
              result.entry
              for result in results
              if result.status in {"UPDATE AVAILABLE", "VERSION DIFFERENT", "RECOVERY REQUIRED"}
          ]
          if not updateable:
              return

          answer = input("Download the listed updates and recover incomplete entries now? [y/N]: ").strip().casefold()
          if answer not in {"y", "yes"}:
              return

          for entry in updateable:
              update_entry(entry, release_cache, manifest_cache, repository_contents_cache)


      def updateable_results(results: list[CheckResult], library_type: LibraryType) -> list[CheckResult]:
          if library_type.is_theme:
              allowed_statuses = {"UPDATE AVAILABLE"}
          else:
              allowed_statuses = {"UPDATE AVAILABLE", "VERSION DIFFERENT", "RECOVERY REQUIRED"}

          return [
              result
              for result in results
              if result.entry.library_type == library_type and result.status in allowed_statuses
          ]


      def update_selected_results(
          results: list[CheckResult],
          library_type: LibraryType,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          updateable = updateable_results(results, library_type)
          if not updateable:
              print(f"No {library_type.label.lower()} are ready to update.")
              return

          rows = [
              f"{result.entry.label}\t{result.entry.version_label}\t{result.remote_version or '-'}\t{result.status}\t{result.message or '-'}"
              for result in updateable
          ]
          selected_rows = fzf_select(
              rows,
              f"update {library_type.label.lower()}> ",
              "TAB selects entries; ENTER updates the selected entries.",
              multi=True,
          )
          selected = set(selected_rows)
          selected_results = [result for result, row in zip(updateable, rows, strict=True) if row in selected]
          if not selected_results:
              return

          answer = input(
              f"Update {len(selected_results)} selected {library_type.label.lower()} now? [y/N]: "
          ).strip().casefold()
          if answer not in {"y", "yes"}:
              return

          for result in selected_results:
              update_entry(result.entry, release_cache, manifest_cache, repository_contents_cache)


      def update_all_results(
          results: list[CheckResult],
          library_type: LibraryType,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          updateable = updateable_results(results, library_type)
          if not updateable:
              print(f"No {library_type.label.lower()} are ready to update.")
              return

          print(f"{len(updateable)} {library_type.label.lower()} are ready to update:")
          for result in updateable:
              print(f"  {result.entry.label} ({result.entry.version_label} -> {result.remote_version or '-'})")

          answer = input(
              f"Update all {len(updateable)} listed {library_type.label.lower()} now? [y/N]: "
          ).strip().casefold()
          if answer not in {"y", "yes"}:
              return

          for result in updateable:
              update_entry(result.entry, release_cache, manifest_cache, repository_contents_cache)


      def check_library_type(
          library_type: LibraryType,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> list[CheckResult]:
          try:
              entries = library_entries(library_type)
          except RuntimeError as error:
              fail(str(error))
              return []

          print(f"Checking {len(entries)} {library_type.label.lower()} for updates…")
          return check_results(entries, release_cache, manifest_cache, repository_contents_cache)


      def manage_updates(
          library_types: tuple[LibraryType, ...],
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          actions = [
              "Plugins",
              "Themes",
              "Update all plugins",
              "Update all themes",
              "Back",
          ]
          selection = fzf_select(
              actions,
              "updates> ",
              "Check one type at a time, or update every available item of that type.",
          )
          choice = selection[0] if selection else "Back"
          if choice == "Back":
              return

          if choice in {"Plugins", "Update all plugins"}:
              library_type = library_types[0]
          else:
              library_type = library_types[1]

          results = check_library_type(
              library_type,
              release_cache,
              manifest_cache,
              repository_contents_cache,
          )
          if choice in {"Plugins", "Themes"}:
              update_selected_results(
                  results,
                  library_type,
                  release_cache,
                  manifest_cache,
                  repository_contents_cache,
              )
          else:
              update_all_results(
                  results,
                  library_type,
                  release_cache,
                  manifest_cache,
                  repository_contents_cache,
              )


      def archive_status(entry: LibraryEntry) -> None:
          if entry.repository is None:
              print(f"[SKIP] {entry.label}: {repository_field(entry.library_type)} is missing or has no GitHub URL")
              return

          try:
              repository = gh_json(f"repos/{entry.repository}")
          except RuntimeError as error:
              if re.search(r"(?:HTTP[ ]*)?404|not found", str(error), flags=re.IGNORECASE):
                  suffix = mark_repository_status(entry, ABANDONED_FIELD)
                  print(f"[ABANDONED] {entry.label}: GitHub returned 404; marked abandoned{suffix}")
                  return
              print(f"[UNAVAILABLE] {entry.label} — {error}")
              return

          archived = repository.get("archived") is True
          if archived:
              suffix = mark_repository_status(entry, ARCHIVED_FIELD)
              print(f"[ARCHIVED] {entry.library_type.label}: {entry.label} ({entry.repository}); marked archived{suffix}")
              return
          status = "ARCHIVED" if archived else "ACTIVE"
          print(f"[{status}] {entry.library_type.label}: {entry.label} ({entry.repository})")


      def update_plugin_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> None:
          result = check_plugin_entry(entry, release_cache, manifest_cache)
          if result.status not in {"UPDATE AVAILABLE", "VERSION DIFFERENT", "RECOVERY REQUIRED"} or result.release is None:
              suffix = f": {result.message}" if result.message else ""
              print(f"[SKIP] {entry.label}: {result.status}{suffix}")
              return

          assets = release_assets(result.release)
          required_files = (MANIFEST_FILE, entry.library_type.payload_file)
          missing_files = [filename for filename in required_files if filename not in assets]
          if missing_files:
              print(f"[SKIP] {entry.label}: latest release is missing {', '.join(missing_files)}")
              return

          if not manifest_is_valid(manifest_file(entry.path)):
              answer = input(
                  f"{entry.label}: manifest.json is invalid. "
                  "Re-download this plugin now? [y/N]: "
              ).strip().casefold()
              if answer not in {"y", "yes"}:
                  print(f"[SKIP] {entry.label}: manifest repair was not confirmed")
                  return

          allowed_files = required_files + entry.library_type.optional_files + tuple(image_names(list(assets)))
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

                  readme_path = temporary_path / README_FILE
                  if not is_nonempty_file(readme_path) and download_repository_readme(entry.repository, readme_path):
                      downloaded.append(README_FILE)

                  set_manifest_repository(temporary_path / MANIFEST_FILE, entry.library_type, entry.repository)

                  downloaded_version = manifest_version(temporary_path / MANIFEST_FILE)
                  if downloaded_version != result.remote_version:
                      raise RuntimeError(
                          f"downloaded manifest version {downloaded_version} does not match checked release version {result.remote_version}"
                      )

                  for filename in downloaded:
                      source = temporary_path / filename
                      destination = manifest_file(entry.path) if filename == MANIFEST_FILE else entry.path / filename
                      staging = destination.with_name(f".{destination.name}.obsidian-library-new")
                      shutil.copyfile(source, staging)
                      os.replace(staging, destination)
              except (OSError, RuntimeError) as error:
                  report_error(f"[FAILED] {entry.label}: {error}")
                  return

          print(f"[UPDATED] {entry.label}: {entry.version_label} -> {result.remote_version} ({', '.join(downloaded)})")


      def write_theme_source(
          directory: Path,
          library_type: LibraryType,
          repository: str,
          source: ThemeSource,
      ) -> list[str]:
          downloaded: list[str] = []
          for remote_file in source.files:
              destination = directory / remote_file.destination_name
              destination.parent.mkdir(parents=True, exist_ok=True)
              download_theme_file(repository, remote_file, destination)
              downloaded.append(remote_file.destination_name)

          readme_path = directory / README_FILE
          if not is_nonempty_file(readme_path) and download_repository_readme(repository, readme_path):
              downloaded.append(README_FILE)

          manifest_path = directory / MANIFEST_FILE
          if not manifest_path.is_file():
              create_theme_manifest(
                  manifest_path,
                  repository,
                  directory.name,
              )
              downloaded.append(MANIFEST_FILE)
          else:
              set_manifest_repository(manifest_path, library_type, repository)

          return downloaded


      def update_theme_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          result = check_theme_entry(entry, release_cache, repository_contents_cache)
          if result.status != "UPDATE AVAILABLE" or result.theme_source is None:
              suffix = f": {result.message}" if result.message else ""
              print(f"[SKIP] {entry.label}: {result.status}{suffix}")
              return

          try:
              with tempfile.TemporaryDirectory(prefix="obsidian-library-theme-update-") as temporary_directory:
                  temporary_path = Path(temporary_directory)
                  downloaded = write_theme_source(temporary_path, entry.library_type, entry.repository, result.theme_source)
                  for filename in downloaded:
                      source = temporary_path / filename
                      destination = manifest_file(entry.path) if filename == MANIFEST_FILE else entry.path / filename
                      staging = destination.with_name(f".{destination.name}.obsidian-library-new")
                      shutil.copyfile(source, staging)
                      os.replace(staging, destination)
          except (OSError, RuntimeError) as error:
              report_error(f"[FAILED] {entry.label}: {error}")
              return

          print(f"[UPDATED] {entry.label}: {entry.version_label} -> {result.remote_version} ({', '.join(downloaded)})")


      def update_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          if entry.library_type.is_theme:
              update_theme_entry(entry, release_cache, repository_contents_cache)
              return
          update_plugin_entry(entry, release_cache, manifest_cache)


      def select_release(repository: str) -> dict[str, Any] | None:
          try:
              releases = gh_list(f"repos/{repository}/releases?per_page=100")
          except RuntimeError as error:
              print(f"[UNAVAILABLE] {repository}: {error}")
              return None

          def eligible(include_prereleases: bool) -> list[dict[str, Any]]:
              return [
                  release for release in releases
                  if release.get("draft") is not True
                  and (include_prereleases or release.get("prerelease") is not True)
                  and isinstance(release.get("tag_name"), str)
              ]

          include_prereleases = False
          while True:
              available = eligible(include_prereleases)
              lines = ["Latest release", *(str(release["tag_name"]) for release in available)]
              if not include_prereleases:
                  lines.append("Show prereleases")
              lines.append("Back")
              selected = fzf_select(lines, "release> ", "Choose a one-time release; it will not be pinned.")
              choice = selected[0] if selected else "Back"
              if choice == "Back":
                  return None
              if choice == "Show prereleases":
                  include_prereleases = True
                  continue
              if choice == "Latest release":
                  return available[0] if available else None
              return next((release for release in available if release.get("tag_name") == choice), None)


      def download_another_version(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          if entry.abandoned:
              print(f"[SKIP] {entry.label}: manifest marks this repository as abandoned")
              return
          if entry.repository is None:
              print(f"[SKIP] {entry.label}: {repository_field(entry.library_type)} is missing or invalid")
              return
          release = select_release(entry.repository)
          if release is None:
              return
          tag = str(release.get("tag_name"))
          destination_kind = fzf_select(["Replace selected entry", "Create side-by-side copy", "Back"], "version destination> ", "Choose where to save the selected release.")
          choice = destination_kind[0] if destination_kind else "Back"
          if choice == "Back":
              return
          destination = entry.path if choice == "Replace selected entry" else entry.path.with_name(f"{entry.path.name}--{re.sub(r'[^0-9A-Za-z._-]+', '-', tag).strip('-')}")
          if choice != "Replace selected entry" and destination.exists():
              print(f"[SKIP] {entry.label}: {destination.name} already exists")
              return

          try:
              with tempfile.TemporaryDirectory(prefix=".obsidian-library-version-", dir=entry.library_type.root) as temporary_directory:
                  staging = Path(temporary_directory) / destination.name
                  staging.mkdir()
                  if entry.library_type.is_theme:
                      source = theme_release_source(release)
                      if source is None or not any(file.destination_name == MANIFEST_FILE for file in source.files):
                          raise RuntimeError(f"release {tag} has no usable theme.css/obsidian.css and manifest.json")
                      downloaded = write_theme_source(staging, entry.library_type, entry.repository, source)
                  else:
                      assets = release_assets(release)
                      required = (MANIFEST_FILE, entry.library_type.payload_file)
                      missing = [name for name in required if name not in assets]
                      if missing:
                          raise RuntimeError(f"release {tag} is missing {', '.join(missing)}")
                      downloaded = []
                      for name in required + entry.library_type.optional_files + tuple(image_names(list(assets))):
                          if name in assets:
                              download_asset(entry.repository, assets[name], staging / name)
                              downloaded.append(name)
                      readme = staging / README_FILE
                      if not is_nonempty_file(readme) and download_repository_readme(entry.repository, readme):
                          downloaded.append(README_FILE)
                      set_manifest_repository(staging / MANIFEST_FILE, entry.library_type, entry.repository)

                  if choice == "Replace selected entry":
                      for source_file in staging.rglob("*"):
                          if not source_file.is_file():
                              continue
                          target = entry.path / source_file.relative_to(staging)
                          target.parent.mkdir(parents=True, exist_ok=True)
                          staged = target.with_name(f".{target.name}.obsidian-library-new")
                          shutil.copyfile(source_file, staged)
                          os.replace(staged, target)
                  else:
                      os.replace(staging, destination)
          except (OSError, RuntimeError) as error:
              report_error(f"[FAILED] {entry.label}: {error}")
              return
          print(f"[DOWNLOADED] {entry.label}: {tag} -> {destination.name}")


      def github_repository_from_value(value: str) -> str:
          matches = re.findall(
              r"(?i)(?:https?://)?(?:www[.])?github[.]com[/:]([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9_.-]+)(?:[/?#>\s]|$)",
              value,
          )
          if matches:
              owner, repository = matches[0]
              return f"{owner}/{repository.removesuffix('.git')}"

          match = re.fullmatch(r"\s*([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9_.-]+)\s*", value)
          if match is None:
              raise RuntimeError("provide a GitHub repository URL or owner/repository")
          return f"{match.group(1)}/{match.group(2).removesuffix('.git')}"


      def normalized_theme_name(value: str) -> str:
          normalized = re.sub(r"[^0-9A-Za-z]+", "-", value.casefold()).strip("-")
          if not normalized:
              raise RuntimeError("theme id or name cannot produce a folder name")
          return normalized


      def theme_identifier(repository: str, source: ThemeSource) -> str:
          manifest = next((remote_file for remote_file in source.files if remote_file.destination_name == MANIFEST_FILE), None)
          if manifest is None:
              raise RuntimeError("an 'obsidian' repository needs manifest.json with an id or name")

          with tempfile.TemporaryDirectory(prefix="obsidian-library-theme-id-") as temporary_directory:
              manifest_file = Path(temporary_directory) / MANIFEST_FILE
              download_theme_file(repository, manifest, manifest_file)
              try:
                  contents = json.loads(manifest_file.read_text(encoding="utf-8"))
              except (OSError, json.JSONDecodeError) as error:
                  raise RuntimeError(f"cannot read valid {MANIFEST_FILE}: {error}") from error

          if not isinstance(contents, dict):
              raise RuntimeError(f"{MANIFEST_FILE} does not contain an object")
          for field in ("id", "name"):
              value = contents.get(field)
              if isinstance(value, str) and value.strip():
                  return value.strip()
          raise RuntimeError(f"{MANIFEST_FILE} has no usable id or name")


      def theme_folder_name(repository: str, source: ThemeSource) -> str:
          repository_name = repository.rsplit("/", 1)[1]
          trimmed_name = repository_name
          while True:
              without_suffix = re.sub(r"(?i)[-_ ](?:main|master|repo)$", "", trimmed_name)
              if without_suffix == trimmed_name:
                  break
              trimmed_name = without_suffix
          if trimmed_name.casefold() in {"main", "master", "repo"}:
              trimmed_name = ""
          if repository_name.casefold() == "obsidian" or trimmed_name.casefold() == "obsidian":
              return normalized_theme_name(theme_identifier(repository, source))
          if not trimmed_name:
              raise RuntimeError(f"repository name '{repository_name}' cannot produce a folder name")
          return trimmed_name


      def plugin_folder_name(manifest_file: Path) -> str:
          try:
              manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError) as error:
              raise RuntimeError(f"cannot read valid {MANIFEST_FILE}: {error}") from error

          plugin_id = manifest.get("id") if isinstance(manifest, dict) else None
          if not isinstance(plugin_id, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", plugin_id):
              raise RuntimeError(f"{MANIFEST_FILE} has no safe plugin id")
          return plugin_id


      def download_plugin(
          library_type: LibraryType,
          repository_value: str,
          release_cache: dict[str, dict[str, Any] | Exception],
      ) -> None:
          try:
              repository = github_repository_from_value(repository_value)
              release = latest_release(repository, release_cache)
              assets = release_assets(release)
              required_files = (MANIFEST_FILE, library_type.payload_file)
              missing_files = [filename for filename in required_files if filename not in assets]
              if missing_files:
                  raise RuntimeError(f"latest release is missing {', '.join(missing_files)}")
          except RuntimeError as error:
              report_error(f"[FAILED] Plugin: {error}")
              return

          if not library_type.root.is_dir():
              report_error(f"[FAILED] Plugin: library directory does not exist: {library_type.root}")
              return

          allowed_files = required_files + library_type.optional_files + tuple(image_names(list(assets)))
          try:
              with tempfile.TemporaryDirectory(prefix=".obsidian-library-plugin-", dir=library_type.root) as temporary_directory:
                  staging_parent = Path(temporary_directory)
                  manifest_path = staging_parent / MANIFEST_FILE
                  download_asset(repository, assets[MANIFEST_FILE], manifest_path)
                  folder_name = plugin_folder_name(manifest_path)
                  destination = library_type.root / folder_name
                  refresh_existing_plugin = False
                  if destination.exists():
                      if not destination.is_dir():
                          print(f"[SKIP] Plugin: {destination} exists but is not a directory")
                          return
                      if manifest_is_valid(manifest_file(destination)):
                          print(f"[SKIP] Plugin: {destination} already exists; use Plugins > Check for updates to recover it")
                          return

                      answer = input(
                          f"{folder_name}: manifest.json is invalid. "
                          "Re-download this plugin now? [y/N]: "
                      ).strip().casefold()
                      if answer not in {"y", "yes"}:
                          print(f"[SKIP] Plugin: manifest repair was not confirmed for {folder_name}")
                          return
                      refresh_existing_plugin = True

                  staging = staging_parent / folder_name
                  staging.mkdir()
                  shutil.move(str(manifest_path), staging / MANIFEST_FILE)
                  downloaded = [MANIFEST_FILE]
                  for filename in allowed_files:
                      if filename == MANIFEST_FILE or filename not in assets:
                          continue
                      download_asset(repository, assets[filename], staging / filename)
                      downloaded.append(filename)
                  readme_path = staging / README_FILE
                  if not is_nonempty_file(readme_path) and download_repository_readme(repository, readme_path):
                      downloaded.append(README_FILE)
                  set_manifest_repository(staging / MANIFEST_FILE, library_type, repository)
                  if refresh_existing_plugin:
                      for filename in downloaded:
                          source = staging / filename
                          refreshed_file = destination / filename
                          staging_file = refreshed_file.with_name(f".{refreshed_file.name}.obsidian-library-new")
                          shutil.copyfile(source, staging_file)
                          os.replace(staging_file, refreshed_file)
                  else:
                      os.replace(staging, destination)
          except (OSError, RuntimeError) as error:
              report_error(f"[FAILED] Plugin: {error}")
              return

          action = "REDOWNLOADED" if refresh_existing_plugin else "DOWNLOADED"
          print(f"[{action}] Plugin: {folder_name} ({', '.join(downloaded)})")


      def download_theme(
          library_type: LibraryType,
          repository_value: str,
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          try:
              repository = github_repository_from_value(repository_value)
              source = theme_source(repository, release_cache, repository_contents_cache)
              folder_name = theme_folder_name(repository, source)
          except (OSError, RuntimeError) as error:
              report_error(f"[FAILED] Theme: {error}")
              return

          destination = library_type.root / folder_name
          if destination.exists():
              print(f"[SKIP] Theme: {destination} already exists")
              return
          if not library_type.root.is_dir():
              report_error(f"[FAILED] Theme: library directory does not exist: {library_type.root}")
              return

          try:
              with tempfile.TemporaryDirectory(prefix=".obsidian-library-theme-", dir=library_type.root) as temporary_directory:
                  staging = Path(temporary_directory) / folder_name
                  staging.mkdir()
                  downloaded = write_theme_source(staging, library_type, repository, source)
                  os.replace(staging, destination)
          except (OSError, RuntimeError) as error:
              report_error(f"[FAILED] Theme: {error}")
              return

          print(f"[DOWNLOADED] Theme: {folder_name} ({source.location}; {', '.join(downloaded)})")


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
              "--bind=right:accept",
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
              print(f"No {library_type.label.lower()} folders were found in {library_type.root}.")
              return []

          rows = [
              f"{entry.label}\t{entry.repository_status_label}\t{entry.manifest_missing_label}\t{entry.author}\t{entry.description}\t{entry.version_label}\t{entry.repository_url_label}"
              for entry in entries
          ]
          selected_rows = fzf_select(
              rows,
              f"{library_type.label.lower()}> ",
              "Columns: name, repository status, manifest missing, author, description, version, repository URL. TAB selects entries; ENTER continues.",
              multi=True,
          )
          selected = set(selected_rows)
          return [entry for entry, row in zip(entries, rows, strict=True) if row in selected]


      def choose_action(library_type: LibraryType) -> str | None:
          actions = [
              "Check for updates",
              "Download another version",
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
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
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
                  results = show_checks(entries, release_cache, manifest_cache, repository_contents_cache)
                  offer_updates(results, release_cache, manifest_cache, repository_contents_cache)
              elif action == "Download another version":
                  for entry in entries:
                      download_another_version(entry, release_cache, repository_contents_cache)
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


      def audit_report_path() -> Path:
          stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
          return Path(os.environ.get("OBSIDIAN_LIBRARY_DOWNLOADS_DIR", DEFAULT_DOWNLOADS_DIR)) / f"obsidian-library-audit-{stamp}.txt"


      def audit_library(library_types: tuple[LibraryType, ...], remote: bool) -> None:
          lines = [f"Obsidian library audit ({'remote' if remote else 'local'})", ""]
          markers: list[tuple[LibraryEntry, str]] = []
          seen_ids: dict[tuple[str, str], list[str]] = {}
          seen_repositories: dict[tuple[str, str], list[str]] = {}

          for entry in all_entries(library_types):
              issues: list[str] = []
              if entry.manifest_missing:
                  issues.append("manifest.json missing or unreadable")
              if entry.repository is None:
                  issues.append(f"{repository_field(entry.library_type)} missing or invalid")
              if not is_nonempty_file(entry.path / entry.library_type.payload_file):
                  issues.append(f"{entry.library_type.payload_file} missing or empty")
              if not is_nonempty_file(entry.path / README_FILE):
                  issues.append("README.md missing or empty")
              if entry.abandoned:
                  issues.append("marked abandoned")
              if entry.archived:
                  issues.append("marked archived")

              seen_ids.setdefault((entry.library_type.label, entry.identifier.casefold()), []).append(entry.path.name)
              if entry.repository is not None:
                  seen_repositories.setdefault((entry.library_type.label, entry.repository.casefold()), []).append(entry.path.name)

              if remote and entry.repository is not None:
                  completed = run([GH_BIN, "api", f"repos/{entry.repository}"])
                  if completed.returncode != 0:
                      detail = completed.stderr.strip() or completed.stdout.strip()
                      if re.search(r"(?:HTTP[ ]*)?404|not found", detail, flags=re.IGNORECASE):
                          issues.append("remote repository returned 404")
                          markers.append((entry, ABANDONED_FIELD))
                      else:
                          issues.append(f"remote check unavailable: {detail or 'unknown error'}")
                  else:
                      try:
                          metadata = json.loads(completed.stdout)
                      except json.JSONDecodeError:
                          issues.append("remote repository returned invalid JSON")
                      else:
                          if isinstance(metadata, dict) and metadata.get("archived") is True:
                              issues.append("remote repository is archived")
                              markers.append((entry, ARCHIVED_FIELD))
                          elif isinstance(metadata, dict):
                              result = (
                                  check_theme_entry(entry, {}, {})
                                  if entry.library_type.is_theme
                                  else check_plugin_entry(entry, {}, {})
                              )
                              if result.status == "UPDATE AVAILABLE":
                                  issues.append(f"update available: {result.remote_version or '-'}")

              status = "; ".join(issues) if issues else "OK"
              lines.append(f"[{entry.library_type.label}] {entry.label} ({entry.path.name}): {status}")

          for (kind, identity), folders in sorted(seen_ids.items()):
              if len(folders) > 1:
                  lines.append(f"[DUPLICATE {kind} id/name] {identity}: {', '.join(folders)}")
          for (kind, repository), folders in sorted(seen_repositories.items()):
              if len(folders) > 1:
                  lines.append(f"[DUPLICATE {kind} repository] {repository}: {', '.join(folders)}")

          report = audit_report_path()
          report.parent.mkdir(parents=True, exist_ok=True)
          report.write_text("\n".join(lines) + "\n", encoding="utf-8")
          print(f"Audit report: {report}")

          if remote:
              for entry, field in markers:
                  answer = input(f"{entry.label}: add {field}: yes to manifest.json? [y/N]: ").strip().casefold()
                  if answer in {"y", "yes"}:
                      suffix = mark_repository_status(entry, field)
                      print(f"[{field}] {entry.label}{suffix}")


      def main() -> int:
          parser = argparse.ArgumentParser(description="Manage the local Obsidian plugin and theme library.")
          parser.add_argument("--check-all", action="store_true", help="Check every recoverable plugin and theme without opening fzf.")
          parser.add_argument("--audit", choices=("local", "remote"), help="Write a dated local or remote library audit report.")
          parser.add_argument("--download-plugin", metavar="REPOSITORY", help="Download a plugin release from a GitHub repository into the plugin library.")
          parser.add_argument("--download-theme", metavar="REPOSITORY", help="Download a theme from a GitHub repository into the theme library.")
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
                  (),
                  is_theme=True,
              ),
          )
          release_cache: dict[str, dict[str, Any] | Exception] = {}
          manifest_cache: dict[tuple[str, str], tuple[str, Path]] = {}
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception] = {}

          try:
              if arguments.download_plugin:
                  download_plugin(library_types[0], arguments.download_plugin, release_cache)
                  return 0

              if arguments.download_theme:
                  download_theme(library_types[1], arguments.download_theme, release_cache, repository_contents_cache)
                  return 0

              if arguments.check_all:
                  print_heading("Check all updates")
                  show_checks(all_entries(library_types), release_cache, manifest_cache, repository_contents_cache)
                  return 0

              if arguments.audit:
                  audit_library(library_types, arguments.audit == "remote")
                  return 0

              menu_items = ["Check for updates", "Audit local library", "Audit remote library", "Plugins", "Themes", "Download a plugin", "Download a theme", "Quit"]
              while True:
                  selection = fzf_select(menu_items, "obsidian-library> ", "Choose a library or check every installed item.")
                  choice = selection[0] if selection else "Quit"
                  if choice == "Plugins":
                      manage_type(library_types[0], release_cache, manifest_cache, repository_contents_cache)
                  elif choice == "Themes":
                      manage_type(library_types[1], release_cache, manifest_cache, repository_contents_cache)
                  elif choice == "Audit local library":
                      audit_library(library_types, False)
                  elif choice == "Audit remote library":
                      audit_library(library_types, True)
                  elif choice == "Download a plugin":
                      repository = input("GitHub repository URL, owner/repository, or text containing a GitHub link: ").strip()
                      if repository:
                          download_plugin(library_types[0], repository, release_cache)
                      else:
                          print("[SKIP] Plugin: no repository was provided")
                      input("\\nPress ENTER to return to the main menu.")
                  elif choice == "Download a theme":
                      repository = input("GitHub repository URL or owner/repository: ").strip()
                      if repository:
                          download_theme(library_types[1], repository, release_cache, repository_contents_cache)
                      else:
                          print("[SKIP] Theme: no repository was provided")
                      input("\\nPress ENTER to return to the main menu.")
                  elif choice == "Check for updates":
                      manage_updates(
                          library_types,
                          release_cache,
                          manifest_cache,
                          repository_contents_cache,
                      )
                      input("\nPress ENTER to return to the main menu.")
                  else:
                      return 0
          finally:
              for _, cached_manifest in manifest_cache.values():
                  shutil.rmtree(cached_manifest.parent, ignore_errors=True)


      if __name__ == "__main__":
          raise SystemExit(main())
      PY
      ) "$@"
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
