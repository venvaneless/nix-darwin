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

      exec python3 - "$@" <<'PY'
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
          is_theme: bool = False


      @dataclass(frozen=True)
      class LibraryEntry:
          library_type: LibraryType
          path: Path
          repository: str
          local_version: str | None

          @property
          def label(self) -> str:
              return self.path.name

          @property
          def version_label(self) -> str:
              return self.local_version or "unversioned"


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

              try:
                  repository = github_repository(child / REPOSITORY_FILE)
                  if library_type.is_theme:
                      payload = child / library_type.payload_file
                      if not payload.is_file():
                          raise RuntimeError(f"missing {library_type.payload_file}")
                      local_version = optional_manifest_version(child / MANIFEST_FILE)
                  else:
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


      def preview_file(filenames: list[str]) -> tuple[str, str] | None:
          image_pattern = re.compile(r"^(?:preview|screenshot|screencap)(?:[.][^.]+)?(?:[.](?:avif|gif|jpe?g|png|svg|webp))?$", re.IGNORECASE)
          for prefix in ("preview", "screenshot", "screencap"):
              matches = sorted(
                  filename
                  for filename in filenames
                  if (filename.casefold() == prefix or filename.casefold().startswith(f"{prefix}."))
                  and image_pattern.fullmatch(filename)
              )
              if matches:
                  source_name = matches[0]
                  suffix = Path(source_name).suffix
                  return source_name, f"preview{suffix}"
          return None


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

          preview = preview_file(list(assets))
          if preview is not None:
              source_name, destination_name = preview
              files.append(ThemeRemoteFile(source_name, destination_name, release_asset=assets[source_name]))

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

          preview = preview_file(list(files_by_name))
          if preview is not None:
              source_name, destination_name = preview
              files.append(repository_file(source_name, destination_name))

          return ThemeSource("repository root", None, tuple(files))


      def release_theme_source_with_repository_files(
          repository: str,
          source: ThemeSource,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> ThemeSource:
          # Keep release CSS authoritative, but add repository metadata or a
          # preview when the release did not include the file.
          if any(remote_file.destination_name == MANIFEST_FILE for remote_file in source.files) and any(
              remote_file.destination_name.startswith("preview") for remote_file in source.files
          ):
              return source

          try:
              files_by_name = repository_root_files(repository, repository_contents_cache)
          except RuntimeError:
              return source

          files = list(source.files)
          if MANIFEST_FILE in files_by_name and not any(remote_file.destination_name == MANIFEST_FILE for remote_file in files):
              files.append(ThemeRemoteFile(MANIFEST_FILE, MANIFEST_FILE, repository_path=files_by_name[MANIFEST_FILE]["path"]))

          if not any(remote_file.destination_name.startswith("preview") for remote_file in files):
              preview = preview_file(list(files_by_name))
              if preview is not None:
                  source_name, destination_name = preview
                  files.append(ThemeRemoteFile(source_name, destination_name, repository_path=files_by_name[source_name]["path"]))

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


      def update_plugin_entry(
          entry: LibraryEntry,
          release_cache: dict[str, dict[str, Any] | Exception],
          manifest_cache: dict[tuple[str, str], tuple[str, Path]],
      ) -> None:
          result = check_plugin_entry(entry, release_cache, manifest_cache)
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

          print(f"[UPDATED] {entry.label}: {entry.version_label} -> {result.remote_version} ({', '.join(downloaded)})")


      def write_theme_source(directory: Path, repository: str, source: ThemeSource) -> list[str]:
          downloaded: list[str] = []
          for remote_file in source.files:
              destination = directory / remote_file.destination_name
              destination.parent.mkdir(parents=True, exist_ok=True)
              download_theme_file(repository, remote_file, destination)
              downloaded.append(remote_file.destination_name)
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
                  downloaded = write_theme_source(temporary_path, entry.repository, result.theme_source)
                  for filename in downloaded:
                      source = temporary_path / filename
                      destination = entry.path / filename
                      staging = destination.with_name(f".{destination.name}.obsidian-library-new")
                      shutil.copyfile(source, staging)
                      os.replace(staging, destination)
          except (OSError, RuntimeError) as error:
              print(f"[FAILED] {entry.label}: {error}")
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


      def github_repository_from_value(value: str) -> str:
          match = re.search(r"(?:github[.]com[/:])?([^/\\s]+)/([^/\\s#]+)", value.strip())
          if match is None:
              raise RuntimeError("provide a GitHub repository URL or owner/repository")

          owner, repository = match.groups()
          repository = repository.removesuffix(".git").rstrip("/")
          if not owner or not repository:
              raise RuntimeError("provide a valid GitHub repository URL or owner/repository")
          return f"{owner}/{repository}"


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
              print(f"[FAILED] Theme: {error}")
              return

          destination = library_type.root / folder_name
          if destination.exists():
              print(f"[SKIP] Theme: {destination} already exists")
              return
          if not library_type.root.is_dir():
              print(f"[FAILED] Theme: library directory does not exist: {library_type.root}")
              return

          try:
              with tempfile.TemporaryDirectory(prefix=".obsidian-library-theme-", dir=library_type.root) as temporary_directory:
                  staging = Path(temporary_directory) / folder_name
                  staging.mkdir()
                  downloaded = write_theme_source(staging, repository, source)
                  (staging / REPOSITORY_FILE).write_text(f"https://github.com/{repository}\\n", encoding="utf-8")
                  os.replace(staging, destination)
          except (OSError, RuntimeError) as error:
              print(f"[FAILED] Theme: {error}")
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
              f"{entry.label}\t{entry.version_label}\t{entry.repository}"
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
                  show_checks(entries, release_cache, manifest_cache, repository_contents_cache)
              elif action == "Update":
                  for entry in entries:
                      update_entry(entry, release_cache, manifest_cache, repository_contents_cache)
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
              if arguments.download_theme:
                  download_theme(library_types[1], arguments.download_theme, release_cache, repository_contents_cache)
                  return 0

              if arguments.check_all:
                  print_heading("Check all updates")
                  show_checks(all_entries(library_types), release_cache, manifest_cache, repository_contents_cache)
                  return 0

              menu_items = ["Plugins", "Themes", "Download theme", "Check all updates", "Quit"]
              while True:
                  selection = fzf_select(menu_items, "obsidian-library> ", "Choose a library or check every installed item.")
                  choice = selection[0] if selection else "Quit"
                  if choice == "Plugins":
                      manage_type(library_types[0], release_cache, manifest_cache, repository_contents_cache)
                  elif choice == "Themes":
                      manage_type(library_types[1], release_cache, manifest_cache, repository_contents_cache)
                  elif choice == "Download theme":
                      repository = input("GitHub repository URL or owner/repository: ").strip()
                      if repository:
                          download_theme(library_types[1], repository, release_cache, repository_contents_cache)
                      else:
                          print("[SKIP] Theme: no repository was provided")
                      input("\\nPress ENTER to return to the main menu.")
                  elif choice == "Check all updates":
                      print_heading("Check all updates")
                      show_checks(all_entries(library_types), release_cache, manifest_cache, repository_contents_cache)
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
