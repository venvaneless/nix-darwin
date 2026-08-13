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
  # ---- SHARED PATHS ---- #
  # The permanent plugin and theme library lives on the external backup
  # volume, so its root comes from the centralized path definitions.
  #
  # ** Interpolated into the Python source below. The heredoc is quoted,
  # ** which stops runtime shell expansion, but Nix still substitutes
  # ** ${...} while the derivation is built.
  paths = import ../../../options/paths.nix { };
  backupPaths = paths.darwin.backups;

  # ---- Obsidian library manager
  # Python is included with this command. GitHub CLI and fzf are already
  # installed globally, so their existing store paths are used directly.
  obsidianLibrary = pkgs.writeShellApplication {
    name = "obsidian-library";

    runtimeInputs = [
      pkgs.nodejs
      pkgs.python3
    ];

    text = ''
      export OBSIDIAN_LIBRARY_GH="${pkgs.gh}/bin/gh"
      export OBSIDIAN_LIBRARY_FZF="${pkgs.fzf}/bin/fzf"
      export OBSIDIAN_LIBRARY_CURL="${pkgs.curl}/bin/curl"
      export OBSIDIAN_LIBRARY_NODE="${pkgs.nodejs}/bin/node"

      # Keep standard input attached to the terminal for the interactive
      # menus; feeding Python through stdin makes every input() raise EOF.
      exec python3 <(
        ${pkgs.coreutils}/bin/cat <<'PY' | ${pkgs.gnused}/bin/sed 's/^      //'
      #!/usr/bin/env python3
      #
      # Obsidian plugin and theme library manager.
      #
      # The manager intentionally has no third-party Python dependencies and
      # only downloads the allowed release assets or theme repository files.

      from __future__ import annotations

      import argparse
      import base64
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
          "${backupPaths.obsidianExtensions}/"
      )
      DEFAULT_THEMES_DIR = Path(
          "${backupPaths.obsidianThemes}/"
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
      CURL_BIN = os.environ["OBSIDIAN_LIBRARY_CURL"]
      NODE_BIN = os.environ["OBSIDIAN_LIBRARY_NODE"]

      BLOCKED_DOWNLOAD_NAMES = {
          "agents",
          "claude",
          "license",
          "changelog",
          "contributing",
          "security",
          "privacy",
      }

      BLOCKED_DOWNLOAD_FILES = {
          "agents.md",
          "changelog.md",
		  "contributing.md",
		  "claude.md",
          "readme-zh_cn.md",
          "readme-zh_tw.md",
          "readme-zh.md",
          "readme-cn.md",
          "readme-tw.md",
      }

      BATCH_FAILURES: list[str] = []


      def is_blocked_download_name(value: str) -> bool:
          filename = Path(value).name.casefold()

          if filename in BLOCKED_DOWNLOAD_FILES:
              return True

          return any(
              filename == blocked_name
              or filename.startswith(f"{blocked_name}.")
              for blocked_name in BLOCKED_DOWNLOAD_NAMES
          )


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
          BATCH_FAILURES.append(message)
          fail(message)
          try:
              error_log_path().parent.mkdir(parents=True, exist_ok=True)
              with error_log_path().open("a", encoding="utf-8") as error_log:
                  error_log.write(f"Error: {message}\n")
          except OSError as error:
              fail(f"could not save the error log: {error}")


      def write_batch_failure_report(library_type: LibraryType) -> None:
          if not BATCH_FAILURES:
              return
          stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
          report = Path(
              os.environ.get("OBSIDIAN_LIBRARY_DOWNLOADS_DIR", DEFAULT_DOWNLOADS_DIR)
          ) / f"obsidian-library-{library_type.label.casefold()}-download-failures-{stamp}.txt"
          try:
              report.parent.mkdir(parents=True, exist_ok=True)
              report.write_text("\n".join(BATCH_FAILURES) + "\n", encoding="utf-8")
          except OSError as error:
              fail(f"could not save the batch failure report: {error}")
              return
          print(f"Batch failure report: {report}")


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


      def repository_package_metadata(repository: str) -> dict[str, Any]:
          # A missing package manifest is normal for many Obsidian projects.
          # Only use it when it is valid JSON and contains string metadata.
          try:
              package_file = gh_json(f"repos/{repository}/contents/package.json")
          except RuntimeError:
              return {}

          encoded = package_file.get("content")
          if not isinstance(encoded, str):
              return {}

          try:
              decoded = base64.b64decode(encoded).decode("utf-8")
              metadata = json.loads(decoded)
          except (ValueError, UnicodeDecodeError, json.JSONDecodeError):
              return {}

          return metadata if isinstance(metadata, dict) else {}


      def create_plugin_manifest(manifest_path: Path, repository: str, folder_name: str) -> None:
          metadata = repository_package_metadata(repository)
          identifier = metadata.get("id")
          if not isinstance(identifier, str) or not identifier.strip():
              identifier = metadata.get("name")
          if not isinstance(identifier, str) or not identifier.strip():
              identifier = folder_name

          display_name = metadata.get("name")
          if not isinstance(display_name, str) or not display_name.strip():
              display_name = identifier

          version = metadata.get("version")
          if not isinstance(version, str) or not version.strip():
              version = "0.0.0"

          min_app_version = metadata.get("minAppVersion")
          if not isinstance(min_app_version, str) or not min_app_version.strip():
              min_app_version = "0.0.0"

          author = metadata.get("author")
          if not isinstance(author, str) or not author.strip():
              author = repository.split("/", 1)[0]

          manifest = {
              "id": identifier.strip(),
              "name": display_name.strip(),
              "version": version.strip(),
              "minAppVersion": min_app_version.strip(),
              "author": author.strip(),
              PLUGIN_URL_FIELD: f"https://github.com/{repository}",
              "generatedManifest": True,
          }

          if manifest_path.is_symlink():
              raise RuntimeError(f"refusing to replace symlinked {MANIFEST_FILE}: {manifest_path}")

          staging = manifest_path.with_name(f".{manifest_path.name}.obsidian-library-new")
          try:
              staging.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
              os.replace(staging, manifest_path)
          except OSError:
              staging.unlink(missing_ok=True)
              raise


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
              and not is_blocked_download_name(asset["name"])
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
          metadata = gh_json(
              f"repos/{repository}/contents/{repository_path}"
          )

          download_url = metadata.get("download_url")
          if not isinstance(download_url, str) or not download_url:
              raise RuntimeError(
                  f"repository file has no usable download URL: {repository_path}"
              )

          completed = run(
              [
                  CURL_BIN,
                  "--fail",
                  "--location",
                  "--silent",
                  "--show-error",
                  "--output",
                  str(destination),
                  download_url,
              ],
          )
          if completed.returncode != 0:
              detail = completed.stderr.strip() or completed.stdout.strip()
              raise RuntimeError(
                  detail or f"could not download repository file {repository_path}"
              )

          if not is_nonempty_file(destination):
              raise RuntimeError(
                  f"downloaded repository file is empty: {repository_path}"
              )


      def find_matching_file(
          root: Path,
          filename: str,
          size: int,
      ) -> Path | None:
          if not root.is_dir():
              return None

          for candidate in root.rglob("*"):
              try:
                  if not candidate.is_file():
                      continue

                  if candidate.name.casefold() != filename.casefold():
                      continue

                  if candidate.stat().st_size != size:
                      continue

                  return candidate
              except OSError:
                  continue

          return None


      def download_repository_readme(
          repository: str,
          destination: Path,
          existing_root: Path | None = None,
      ) -> bool:
          metadata = gh_json(
              f"repos/{repository}/readme"
          )

          readme_name = metadata.get("name")
          readme_size = metadata.get("size")
          download_url = metadata.get("download_url")

          if not isinstance(readme_name, str):
              return False

          if not isinstance(readme_size, int):
              return False

          if not isinstance(download_url, str) or not download_url:
              return False

          readme_names = {
              "readme",
              "readme.md",
              "readme.markdown",
              "readme.org",
              "readme.txt",
          }

          search_roots = [
              destination.parent,
          ]

          if existing_root is not None:
              search_roots.append(
                  existing_root
              )

          for search_root in search_roots:
              if not search_root.is_dir():
                  continue

              for candidate in search_root.rglob("*"):
                  try:
                      if not candidate.is_file():
                          continue

                      if candidate.name.casefold() not in readme_names:
                          continue

                      if candidate.stat().st_size != readme_size:
                          continue

                      return False

                  except OSError:
                      continue

          destination.parent.mkdir(
              parents=True,
              exist_ok=True,
          )

          completed = run(
              [
                  CURL_BIN,
                  "--fail",
                  "--location",
                  "--silent",
                  "--show-error",
                  "--output",
                  str(destination),
                  download_url,
              ],
          )

          if completed.returncode != 0:
              return False

          return is_nonempty_file(
              destination
          )


      def download_repository_documentation(
              repository: str,
              directory: Path,
              existing_root: Path | None = None,
              include_theme_snippets: bool = False,
          ) -> tuple[list[str], bool]:
              tree = gh_json(
                  f"repos/{repository}/git/trees/HEAD?recursive=1"
              ).get("tree")
    
              if not isinstance(tree, list):
                  return [], False
    
              documentation_suffixes = {
                  ".md",
                  ".markdown",
                  ".org",
              }

              documentation_folders = {
                  "doc",
                  "docs",
                  "documentation",
                  "wiki",
              }

              image_suffixes = {
                  ".gif",
                  ".jpeg",
                  ".jpg",
                  ".png",
                  ".webp",
              }
    
              image_folders = {
                  "asset",
                  "assets",
                  "gallery",
                  "galleries",
                  "img",
                  "imgs",
                  "image",
                  "images",
                  "preview",
                  "previews",
                  "screenshot",
                  "screenshots",
              }
    
              image_keywords = (
                  "image",
                  "preview",
                  "screencap",
                  "screen",
                  "screenshot",
              )
    
              readme_names = {
                  "readme",
                  "readme.md",
                  "readme.markdown",
                  "readme.org",
                  "readme.txt",
              }
    
              repository_files: list[tuple[str, int]] = []
    
              for item in tree:
                  if not isinstance(item, dict):
                      continue
    
                  if item.get("type") != "blob":
                      continue
    
                  repository_path = item.get("path")
                  remote_size = item.get("size")
    
                  if not isinstance(repository_path, str):
                      continue
    
                  if not isinstance(remote_size, int):
                      continue

                  if is_blocked_download_name(repository_path):
                      continue
    
                  path = Path(repository_path)
                  suffix = path.suffix.casefold()
                  path_parts = tuple(
                      part.casefold()
                      for part in path.parts
                  )

                  # Ignore hidden repository folders and dependencies.
                  if any(
                      part.startswith(".")
                      for part in path.parts[:-1]
                  ):
                      continue

                  if "node_modules" in path_parts[:-1]:
                      continue

                  is_root_readme = (
                      len(path.parts) == 1
                      and path.name.casefold() in readme_names
                  )

                  # Markdown and OrgMode files qualify regardless of location.
                  is_documentation = (
                      suffix in documentation_suffixes
                      and not is_root_readme
                  )

                  # Every file inside recognized documentation folders is
                  # preserved, including helper scripts such as Lua filters.
                  is_documentation_folder_file = (
                      not is_root_readme
                      and any(
                          part in documentation_folders
                          for part in path_parts[:-1]
                      )
                  )

                  is_image = (
                      suffix in image_suffixes
                      and (
                          any(
                              keyword in part
                              for part in path_parts[:-1]
                              for keyword in image_folders
                          )
                          or any(
                              keyword in path.name.casefold()
                              for keyword in image_keywords
                          )
                      )
                  )

                  is_theme_snippet = (
                      include_theme_snippets
                      and suffix == ".css"
                      and len(path_parts) > 1
                      and path_parts[0] == "snippets"
                  )
    
                  if not (
                      is_documentation
                      or is_documentation_folder_file
                      or is_image
                      or is_theme_snippet
                  ):
                      continue
    
                  repository_files.append(
                      (
                          repository_path,
                          remote_size,
                      )
                  )
    
              use_repository_subfolder = (
                  len(repository_files) > 1
                  or any(
                      "/" in repository_path
                      for repository_path, _ in repository_files
                  )
              )
    
              if existing_root is not None:
                  existing_repo = existing_root / "repo"
    
                  if existing_repo.is_dir():
                      try:
                          has_directory = any(
                              candidate.is_dir()
                              for candidate in existing_repo.iterdir()
                          )
    
                          existing_files = [
                              candidate
                              for candidate in existing_repo.rglob("*")
                              if candidate.is_file()
                          ]
    
                          if has_directory or len(existing_files) > 1:
                              use_repository_subfolder = True
                      except OSError:
                          pass
    
              downloaded: list[str] = []
    
              for repository_path, remote_size in sorted(
                  repository_files
              ):
                  if use_repository_subfolder:
                      destination_name = (
                          f"repo/{repository_path}"
                      )
                  else:
                      destination_name = (
                          Path(repository_path).name
                      )
    
                  destination = (
                      directory / destination_name
                  )
    
                  if is_nonempty_file(destination):
                      continue
    
                  filename = Path(
                      repository_path
                  ).name
    
                  existing_file = find_matching_file(
                      directory,
                      filename,
                      remote_size,
                  )
    
                  if existing_file is None and existing_root is not None:
                      existing_file = find_matching_file(
                          existing_root,
                          filename,
                          remote_size,
                      )
    
                  if existing_file is not None:
                      destination.parent.mkdir(
                          parents=True,
                          exist_ok=True,
                      )

                      if existing_file != destination:
                          shutil.copyfile(
                              existing_file,
                              destination,
                          )

                      downloaded.append(
                          destination_name
                      )

                      continue
    
                  destination.parent.mkdir(
                      parents=True,
                      exist_ok=True,
                  )
    
                  download_repository_file(
                      repository,
                      repository_path,
                      destination,
                  )
    
                  downloaded.append(
                      destination_name
                  )
    
              return (
                  downloaded,
                  use_repository_subfolder,
              )


      def move_readme_to_repo_when_needed(
          directory: Path,
          downloaded: list[str],
          use_repository_subfolder: bool,
          keep_readme_at_root: bool = False,
      ) -> None:
          if keep_readme_at_root:
              return

          root_readme = directory / README_FILE
          repo_readme = directory / "repo" / README_FILE

          if use_repository_subfolder:
              if root_readme.is_file():
                  repo_readme.parent.mkdir(
                      parents=True,
                      exist_ok=True,
                  )

                  if not repo_readme.exists():
                      shutil.move(
                          root_readme,
                          repo_readme,
                      )

              if README_FILE in downloaded:
                  downloaded.remove(
                      README_FILE
                  )

              repo_name = f"repo/{README_FILE}"

              if repo_readme.is_file() and repo_name not in downloaded:
                  downloaded.append(
                      repo_name
                  )

              return

          if repo_readme.is_file() and not root_readme.exists():
              shutil.move(
                  repo_readme,
                  root_readme,
              )

          repo_name = f"repo/{README_FILE}"

          if repo_name in downloaded:
              downloaded.remove(
                  repo_name
              )

          if root_readme.is_file() and README_FILE not in downloaded:
              downloaded.append(
                  README_FILE
              )

          repo_directory = directory / "repo"

          try:
              repo_directory.rmdir()
          except OSError:
              pass


      def download_plugin_release_data(
          repository: str,
          assets: dict[str, dict[str, Any]],
          directory: Path,
      ) -> list[str]:
          data_asset = assets.get("data.json")
          if data_asset is None:
              return []

          destination_name = "data.json"
          destination = directory / destination_name

          if is_nonempty_file(destination):
              return []

          destination.parent.mkdir(
              parents=True,
              exist_ok=True,
          )

          download_asset(
              repository,
              data_asset,
              destination,
          )

          return [destination_name]


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


      def javascript_is_valid(script_file: Path) -> bool:
          if not is_nonempty_file(script_file) or script_file.is_symlink():
              return False
          return run([NODE_BIN, "--check", str(script_file)]).returncode == 0


      def stylesheet_is_valid(stylesheet_file: Path) -> bool:
          # CSS has no built-in parser in Python. This rejects the structural
          # errors which leave Obsidian unable to read a stylesheet.
          if not is_nonempty_file(stylesheet_file) or stylesheet_file.is_symlink():
              return False

          checker = """
      const source = require('node:fs').readFileSync(process.argv[1], 'utf8');
      let depth = 0, quote = String(), escaped = false, comment = false;
      for (let index = 0; index < source.length; index += 1) {
        const character = source[index], next = source[index + 1] || String();
        if (comment) { if (character === '*' && next === '/') { comment = false; index += 1; } continue; }
        if (quote) { if (escaped) escaped = false; else if (character === '\\\\') escaped = true; else if (character === quote) quote = String(); continue; }
        if (character === '/' && next === '*') { comment = true; index += 1; }
        else if (character === '\"' || character === "'") quote = character;
        else if (character === '{') depth += 1;
        else if (character === '}') { depth -= 1; if (depth < 0) process.exit(1); }
      }
      if (comment || quote || depth !== 0) process.exit(1);
          """
          return run([NODE_BIN, "-e", checker, str(stylesheet_file)]).returncode == 0


      def plugin_core_is_healthy(directory: Path) -> bool:
          stylesheet = directory / "styles.css"
          return (
              manifest_is_valid(directory / MANIFEST_FILE)
              and javascript_is_valid(directory / "main.js")
              and (not stylesheet.exists() or stylesheet_is_valid(stylesheet))
          )


      def theme_core_is_healthy(directory: Path) -> bool:
          return (
              manifest_is_valid(directory / MANIFEST_FILE)
              and stylesheet_is_valid(directory / "theme.css")
          )


      def image_names(filenames: list[str]) -> list[str]:
          image_suffixes = {".gif", ".jpeg", ".jpg", ".png", ".webp"}
          return sorted(filename for filename in filenames if Path(filename).suffix.casefold() in image_suffixes)


      def theme_release_source(
          release: dict[str, Any],
      ) -> ThemeSource | None:
          assets = release_assets(
              release
          )

          if (
              "theme.css" not in assets
              and "obsidian.css" not in assets
          ):
              return None

          files: list[ThemeRemoteFile] = []

          for asset_name, asset in assets.items():
              destination_name = asset_name

              # Obsidian requires theme.css. Fall back to obsidian.css when
              # the release does not provide theme.css itself.
              if (
                  asset_name == "obsidian.css"
                  and "theme.css" not in assets
              ):
                  destination_name = "theme.css"

              files.append(
                  ThemeRemoteFile(
                      asset_name,
                      destination_name,
                      release_asset=asset,
                  )
              )

          tag_name = release.get(
              "tag_name"
          )

          return ThemeSource(
              "latest release",
              (
                  tag_name
                  if isinstance(tag_name, str)
                  and tag_name
                  else None
              ),
              tuple(files),
          )


      def repository_files(
          repository: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> list[dict[str, Any]]:
          cached = repository_contents_cache.get(repository)
          if isinstance(cached, Exception):
              raise cached
          if cached is None:
              try:
                  tree = gh_json(
                      f"repos/{repository}/git/trees/HEAD?recursive=1"
                  ).get("tree")
                  if not isinstance(tree, list):
                      raise RuntimeError("GitHub returned no usable repository tree")

                  cached = [
                      item
                      for item in tree
                      if isinstance(item, dict)
                      and item.get("type") == "blob"
                      and isinstance(item.get("path"), str)
                      and not is_blocked_download_name(item["path"])
                      and "node_modules" not in {
                          part.casefold()
                          for part in Path(item["path"]).parts[:-1]
                      }
                      and not any(
                          part.startswith(".")
                          for part in Path(item["path"]).parts[:-1]
                      )
                  ]
              except RuntimeError as error:
                  repository_contents_cache[repository] = error
                  raise

              repository_contents_cache[repository] = cached

          return cached


      def repository_root_files(
          repository: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> dict[str, dict[str, Any]]:
          return {
              item["path"]: item
              for item in repository_files(
                  repository,
                  repository_contents_cache,
              )
              if "/" not in item["path"]
          }


      def repository_file_path(
          repository: str,
          filename: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> str | None:
          matches = sorted(
              item["path"]
              for item in repository_files(repository, repository_contents_cache)
              if Path(item["path"]).name == filename
          )
          if not matches:
              return None
          return next((path for path in matches if "/" not in path), matches[0])


      def normalized_image_match_name(value: str) -> str:
          return re.sub(
              r"[^0-9a-z]+",
              "",
              value.casefold(),
          )


      def is_theme_image_path(
          repository: str,
          repository_path: str,
      ) -> bool:
          image_suffixes = {
              ".gif",
              ".jpeg",
              ".jpg",
              ".png",
              ".webp",
          }

          path = Path(repository_path)
          if path.suffix.casefold() not in image_suffixes:
              return False

          filename = path.name.casefold()

          # Every supported image directly in the repository root is kept.
          if len(path.parts) == 1:
              return True

          # Screenshot-style keywords may occur anywhere in the filename.
          filename_keywords = (
              "screen",
              "screencap",
              "screenshot",
              "image",
              "preview",
              "previews",
          )
          if any(keyword in filename for keyword in filename_keywords):
              return True

          # Preview/screenshot folder names may contain additional words.
          folder_keywords = (
              "asset",
              "assets",
              "gallery",
              "galleries",
              "img",
              "imgs",
              "image",
              "images",
              "preview",
              "previews",
              "screenshot",
              "screenshots",
          )
          for folder in path.parts[:-1]:
              folder_name = folder.casefold()
              if any(keyword in folder_name for keyword in folder_keywords):
                  return True

          # Also keep images whose filename contains the repository/theme name.
          repository_name = repository.rsplit("/", 1)[1]
          normalized_repository_name = normalized_image_match_name(
              repository_name
          )
          normalized_filename = normalized_image_match_name(
              path.stem
          )

          if (
              normalized_repository_name
              and normalized_repository_name in normalized_filename
          ):
              return True

          return False


      def repository_theme_images(
          repository: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> list[ThemeRemoteFile]:
          image_paths = sorted(
              item["path"]
              for item in repository_files(
                  repository,
                  repository_contents_cache,
              )
              if is_theme_image_path(
                  repository,
                  item["path"],
              )
          )

          use_repository_subfolder = (
              len(image_paths) > 1
              or any("/" in image_path for image_path in image_paths)
          )

          files: list[ThemeRemoteFile] = []
          for image_path in image_paths:
              destination_name = image_path
              if use_repository_subfolder:
                  destination_name = f"repo/{image_path}"

              files.append(
                  ThemeRemoteFile(
                      Path(image_path).name,
                      destination_name,
                      repository_path=image_path,
                  )
              )

          return files


      def theme_repository_source(
          repository: str,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> ThemeSource:
          files_by_name = repository_root_files(
              repository,
              repository_contents_cache,
          )
          if "theme.css" not in files_by_name and "obsidian.css" not in files_by_name:
              raise RuntimeError("repository root has neither theme.css nor obsidian.css")

          def repository_file(filename: str, destination_name: str) -> ThemeRemoteFile:
              item = files_by_name[filename]
              return ThemeRemoteFile(
                  filename,
                  destination_name,
                  repository_path=item["path"],
              )

          files: list[ThemeRemoteFile] = []

          if "theme.css" in files_by_name:
              files.append(
                  repository_file(
                      "theme.css",
                      "theme.css",
                  )
              )

          if "obsidian.css" in files_by_name:
              destination_name = (
                  "obsidian.css"
                  if "theme.css" in files_by_name
                  else "theme.css"
              )
              files.append(
                  repository_file(
                      "obsidian.css",
                      destination_name,
                  )
              )

          if MANIFEST_FILE in files_by_name:
              files.append(
                  repository_file(
                      MANIFEST_FILE,
                      MANIFEST_FILE,
                  )
              )

          if README_FILE in files_by_name:
              files.append(
                  repository_file(
                      README_FILE,
                      README_FILE,
                  )
              )

          files.extend(
              repository_theme_images(
                  repository,
                  repository_contents_cache,
              )
          )

          return ThemeSource(
              "repository root",
              None,
              tuple(files),
          )


      def release_theme_source_with_repository_files(
          repository: str,
          source: ThemeSource,
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> ThemeSource:
          # Keep release CSS authoritative, but add repository metadata and
          # matching repository screenshots that the release does not include.
          try:
              files_by_name = repository_root_files(
                  repository,
                  repository_contents_cache,
              )
          except RuntimeError:
              return source

          files = list(source.files)

          if MANIFEST_FILE in files_by_name and not any(
              remote_file.destination_name == MANIFEST_FILE
              for remote_file in files
          ):
              files.append(
                  ThemeRemoteFile(
                      MANIFEST_FILE,
                      MANIFEST_FILE,
                      repository_path=files_by_name[MANIFEST_FILE]["path"],
                  )
              )

          if README_FILE in files_by_name and not any(
              remote_file.destination_name == README_FILE
              for remote_file in files
          ):
              files.append(
                  ThemeRemoteFile(
                      README_FILE,
                      README_FILE,
                      repository_path=files_by_name[README_FILE]["path"],
                  )
              )

          downloaded_names = {
              remote_file.destination_name
              for remote_file in files
          }

          for remote_file in repository_theme_images(
              repository,
              repository_contents_cache,
          ):
              if remote_file.destination_name in downloaded_names:
                  continue

              files.append(remote_file)
              downloaded_names.add(
                  remote_file.destination_name
              )

          return ThemeSource(
              source.location,
              source.version_label,
              tuple(files),
          )


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


      def download_theme_file(
          repository: str,
          remote_file: ThemeRemoteFile,
          destination: Path,
          search_roots: tuple[Path, ...] = (),
      ) -> bool:
          filename = Path(
              remote_file.destination_name
          ).name

          suffix = Path(filename).suffix.casefold()

          image_suffixes = {
              ".gif",
              ".jpeg",
              ".jpg",
              ".png",
              ".webp",
          }

          readme_names = {
              "readme",
              "readme.md",
              "readme.markdown",
              "readme.org",
              "readme.txt",
          }

          remote_size: int | None = None

          if remote_file.release_asset is not None:
              asset_size = remote_file.release_asset.get("size")

              if isinstance(asset_size, int):
                  remote_size = asset_size

          elif remote_file.repository_path is not None:
              metadata = gh_json(
                  f"repos/{repository}/contents/{remote_file.repository_path}"
              )

              repository_size = metadata.get("size")

              if isinstance(repository_size, int):
                  remote_size = repository_size

          should_deduplicate = (
              suffix in image_suffixes
              or filename.casefold() in readme_names
          )

          if should_deduplicate and remote_size is not None:
              for search_root in search_roots:
                  existing_file = find_matching_file(
                      search_root,
                      filename,
                      remote_size,
                  )

                  if existing_file is not None:
                      return False

          if remote_file.release_asset is not None:
              download_asset(
                  repository,
                  remote_file.release_asset,
                  destination,
              )

              return True

          if remote_file.repository_path is not None:
              download_repository_file(
                  repository,
                  remote_file.repository_path,
                  destination,
              )

              return True

          raise RuntimeError(
              f"theme source file {remote_file.source_name} is incomplete"
          )


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

          allowed_files = tuple(assets)
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

                  if not is_nonempty_file(readme_path) and \
                      download_repository_readme(
                          entry.repository,
                          readme_path,
                          entry.path,
                      ):

                      downloaded.append(README_FILE)

                  repository_downloaded, use_repository_subfolder = \
                      download_repository_documentation(
                          entry.repository,
                          temporary_path,
                          entry.path,
                      )

                  downloaded.extend(
                      repository_downloaded
                  )

                  downloaded.extend(
                      download_plugin_release_data(
                          entry.repository,
                          assets,
                          temporary_path,
                      )
                  )

                  release_readme_exists = any(
                      filename.casefold()
                      in {
                          "readme",
                          "readme.md",
                          "readme.markdown",
                          "readme.org",
                          "readme.txt",
                      }
                      for filename in assets
                  )

                  move_readme_to_repo_when_needed(
                      temporary_path,
                      downloaded,
                      use_repository_subfolder,
                      keep_readme_at_root=release_readme_exists,
                  )

                  set_manifest_repository(temporary_path / MANIFEST_FILE, entry.library_type, entry.repository)

                  downloaded_version = manifest_version(temporary_path / MANIFEST_FILE)
                  if downloaded_version != result.remote_version:
                      raise RuntimeError(
                          f"downloaded manifest version {downloaded_version} does not match checked release version {result.remote_version}"
                      )

                  for filename in downloaded:
                      source = temporary_path / filename
                      destination = manifest_file(entry.path) if filename == MANIFEST_FILE else entry.path / filename
                      destination.parent.mkdir(parents=True, exist_ok=True)
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
          existing_root: Path | None = None,
      ) -> list[str]:
          downloaded: list[str] = []

          search_roots = (
              directory,
          )

          if existing_root is not None:
              search_roots = (
                  directory,
                  existing_root,
              )

          for remote_file in source.files:
              destination = directory / remote_file.destination_name
              destination.parent.mkdir(parents=True, exist_ok=True)

              if download_theme_file(
                  repository,
                  remote_file,
                  destination,
                  search_roots,
              ):
                  downloaded.append(
                      remote_file.destination_name
                  )

          readme_path = directory / README_FILE

          if not is_nonempty_file(readme_path) and \
              download_repository_readme(
                  repository,
                  readme_path,
                  existing_root,
              ):

              downloaded.append(
                  README_FILE
              )

          repository_downloaded, use_repository_subfolder = \
              download_repository_documentation(
                  repository,
                  directory,
                  existing_root,
                  include_theme_snippets=True,
              )

          downloaded.extend(
              repository_downloaded
          )

          release_readme_exists = any(
              remote_file.release_asset is not None
              and remote_file.source_name.casefold()
              in {
                  "readme",
                  "readme.md",
                  "readme.markdown",
                  "readme.org",
                  "readme.txt",
              }
              for remote_file in source.files
          )

          move_readme_to_repo_when_needed(
              directory,
              downloaded,
              use_repository_subfolder,
              keep_readme_at_root=release_readme_exists,
          )

          manifest_path = directory / MANIFEST_FILE

          if not manifest_is_valid(manifest_path):
              create_theme_manifest(
                  manifest_path,
                  repository,
                  directory.name,
              )
              downloaded.append(MANIFEST_FILE)
          else:
              set_manifest_repository(
                  manifest_path,
                  library_type,
                  repository,
              )

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
                  downloaded = write_theme_source(
                      temporary_path,
                      entry.library_type,
                      entry.repository,
                      result.theme_source,
                      entry.path,
                  )
                  for filename in downloaded:
                      source = temporary_path / filename
                      destination = manifest_file(entry.path) if filename == MANIFEST_FILE else entry.path / filename
                      destination.parent.mkdir(parents=True, exist_ok=True)
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
                      for name in assets:
                          if name in assets:
                              download_asset(entry.repository, assets[name], staging / name)
                              downloaded.append(name)
                      readme = staging / README_FILE
                      if not is_nonempty_file(readme) and download_repository_readme(entry.repository, readme):
                          downloaded.append(README_FILE)

                      repository_downloaded, use_repository_subfolder = \
                          download_repository_documentation(
                              entry.repository,
                              staging,
                          )

                      downloaded.extend(
                          repository_downloaded
                      )

                      downloaded.extend(
                          download_plugin_release_data(
                              entry.repository,
                              assets,
                              staging,
                          )
                      )

                      release_readme_exists = any(
                          filename.casefold()
                          in {
                              "readme",
                              "readme.md",
                              "readme.markdown",
                              "readme.org",
                              "readme.txt",
                          }
                          for filename in assets
                      )

                      move_readme_to_repo_when_needed(
                          staging,
                          downloaded,
                          use_repository_subfolder,
                          keep_readme_at_root=release_readme_exists,
                      )

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


      def repository_fallback_name(repository: str) -> str:
          repository_name = repository.rsplit(
              "/",
              1,
          )[1]

          fallback_name = repository_name

          while True:
              cleaned_name = re.sub(
                  r"(?i)[-_ ](?:main|manifest|master|repo|dotfiles|dots)$",
                  "",
                  fallback_name,
              ).rstrip("-_ ")

              if cleaned_name == fallback_name:
                  break

              fallback_name = cleaned_name

          if fallback_name.casefold() in {
              "main",
              "manifest",
              "master",
              "repo",
              "dotfiles",
              "dots",
          }:
              fallback_name = ""

          if not fallback_name:
              raise RuntimeError(
                  f"repository name '{repository_name}' cannot produce a folder name"
              )

          return fallback_name


      def theme_identifier(repository: str, source: ThemeSource) -> str:
          manifest = next(
              (
                  remote_file
                  for remote_file in source.files
                  if remote_file.destination_name == MANIFEST_FILE
              ),
              None,
          )

          if manifest is not None:
              with tempfile.TemporaryDirectory(
                  prefix="obsidian-library-theme-id-"
              ) as temporary_directory:
                  manifest_file = Path(temporary_directory) / MANIFEST_FILE

                  download_theme_file(
                      repository,
                      manifest,
                      manifest_file,
                  )

                  try:
                      contents = json.loads(
                          manifest_file.read_text(
                              encoding="utf-8"
                          )
                      )
                  except (OSError, json.JSONDecodeError):
                      contents = None

              if isinstance(contents, dict):
                  for field in ("name", "id"):
                      value = contents.get(field)

                      if isinstance(value, str) and value.strip():
                          return value.strip()

          return repository_fallback_name(
              repository
          )


      def theme_folder_name(repository: str, source: ThemeSource) -> str:
          return theme_identifier(
              repository,
              source,
          )


      def plugin_folder_name(
          manifest_file: Path,
          repository: str,
      ) -> str:
          try:
              manifest = json.loads(
                  manifest_file.read_text(
                      encoding="utf-8"
                  )
              )
          except (OSError, json.JSONDecodeError) as error:
              raise RuntimeError(
                  f"cannot read valid {MANIFEST_FILE}: {error}"
              ) from error

          if isinstance(manifest, dict):
              for field in ("id", "name"):
                  value = manifest.get(field)

                  if (
                      isinstance(value, str)
                      and value.strip()
                  ):
                      folder_name = value.strip()

                      if (
                          "/" not in folder_name
                          and "\x00" not in folder_name
                          and folder_name not in {".", ".."}
                      ):
                          return folder_name

          return repository_fallback_name(
              repository
          )


      def download_plugin(
          library_type: LibraryType,
          repository_value: str,
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          try:
              repository = github_repository_from_value(repository_value)
              try:
                  release = latest_release(repository, release_cache)
                  assets = release_assets(release)
              except RuntimeError:
                  release = None
                  assets = {}

              # Releases remain preferred, but a repository can supply a
              # complete plugin when its newest release is absent or partial.
              use_repository_core = any(
                  filename not in assets
                  for filename in (MANIFEST_FILE, library_type.payload_file)
              )
              repository_core_paths: dict[str, str | None] = {}
              if use_repository_core:
                  repository_core_paths = {
                      filename: repository_file_path(
                          repository,
                          filename,
                          repository_contents_cache,
                      )
                      for filename in (MANIFEST_FILE, library_type.payload_file, "styles.css")
                  }
              elif "styles.css" not in assets:
                  try:
                      repository_core_paths["styles.css"] = repository_file_path(
                          repository,
                          "styles.css",
                          repository_contents_cache,
                      )
                  except RuntimeError:
                      repository_core_paths["styles.css"] = None
              if use_repository_core and repository_core_paths[library_type.payload_file] is None:
                  raise RuntimeError(
                      "latest release is incomplete and repository has no usable main.js"
                  )
          except RuntimeError as error:
              report_error(f"[FAILED] Plugin: {error}")
              return

          if not library_type.root.is_dir():
              report_error(f"[FAILED] Plugin: library directory does not exist: {library_type.root}")
              return

          allowed_files = tuple(assets)
          try:
              with tempfile.TemporaryDirectory(prefix=".obsidian-library-plugin-", dir=library_type.root) as temporary_directory:
                  staging_parent = Path(temporary_directory)
                  manifest_path = staging_parent / MANIFEST_FILE
                  if use_repository_core and repository_core_paths[MANIFEST_FILE] is not None:
                      download_repository_file(
                          repository,
                          repository_core_paths[MANIFEST_FILE],
                          manifest_path,
                      )
                  elif MANIFEST_FILE in assets:
                      download_asset(repository, assets[MANIFEST_FILE], manifest_path)
                  else:
                      create_plugin_manifest(
                          manifest_path,
                          repository,
                          repository_fallback_name(repository),
                      )

                  folder_name = plugin_folder_name(
                      manifest_path,
                      repository,
                  )
                  destination = library_type.root / folder_name
                  refresh_existing_plugin = False
                  if destination.exists():
                      if not destination.is_dir():
                          print(f"[SKIP] Plugin: {destination} exists but is not a directory")
                          return
                      if plugin_core_is_healthy(destination):
                          print(
                              f"[SKIP] Plugin: {destination} already exists; "
                              "use Plugins > Check for updates to recover it"
                          )
                          return

                      answer = input(
                          f"{folder_name}: plugin core files are missing, empty, or invalid. "
                          "Replace manifest.json and main.js now? [y/N]: "
                      ).strip().casefold()
                      if answer not in {"y", "yes"}:
                          print(f"[SKIP] Plugin: manifest repair was not confirmed for {folder_name}")
                          return
                      refresh_existing_plugin = True

                  staging = staging_parent / folder_name
                  staging.mkdir()
                  shutil.move(str(manifest_path), staging / MANIFEST_FILE)
                  downloaded = [MANIFEST_FILE]

                  for filename in (library_type.payload_file, "styles.css"):
                      source_path = repository_core_paths.get(filename)
                      asset = assets.get(filename)
                      destination_file = staging / filename
                      if use_repository_core and source_path is not None:
                          download_repository_file(repository, source_path, destination_file)
                      elif asset is not None:
                          download_asset(repository, asset, destination_file)
                      else:
                          continue
                      downloaded.append(filename)

                  for filename in allowed_files:
                      if filename in {MANIFEST_FILE, library_type.payload_file, "styles.css"}:
                          continue
                      download_asset(repository, assets[filename], staging / filename)
                      downloaded.append(filename)

                  if not javascript_is_valid(staging / library_type.payload_file):
                      raise RuntimeError("downloaded main.js is empty or has invalid JavaScript syntax")
                  if (staging / "styles.css").exists() and not stylesheet_is_valid(staging / "styles.css"):
                      raise RuntimeError("downloaded styles.css is empty or malformed")
                  readme_path = staging / README_FILE

                  existing_root = (
                      destination
                      if refresh_existing_plugin
                      else None
                  )

                  if not is_nonempty_file(readme_path) and \
                      download_repository_readme(
                          repository,
                          readme_path,
                          existing_root,
                      ):

                      downloaded.append(README_FILE)

                  repository_downloaded, use_repository_subfolder = \
                      download_repository_documentation(
                          repository,
                          staging,
                          existing_root,
                      )

                  downloaded.extend(
                      repository_downloaded
                  )

                  downloaded.extend(
                      download_plugin_release_data(
                          repository,
                          assets,
                          staging,
                      )
                  )

                  release_readme_exists = any(
                      filename.casefold()
                      in {
                          "readme",
                          "readme.md",
                          "readme.markdown",
                          "readme.org",
                          "readme.txt",
                      }
                      for filename in assets
                  )

                  move_readme_to_repo_when_needed(
                      staging,
                      downloaded,
                      use_repository_subfolder,
                      keep_readme_at_root=release_readme_exists,
                  )

                  set_manifest_repository(staging / MANIFEST_FILE, library_type, repository)

                  if refresh_existing_plugin:
                      for filename in downloaded:
                          source = staging / filename
                          refreshed_file = destination / filename
                          refreshed_file.parent.mkdir(parents=True, exist_ok=True)
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
          refresh_existing_theme = False
          if destination.exists():
              if not destination.is_dir():
                  print(f"[SKIP] Theme: {destination} exists but is not a directory")
                  return
              if theme_core_is_healthy(destination):
                  print(f"[SKIP] Theme: {destination} already exists")
                  return
              answer = input(
                  f"{folder_name}: theme core files are missing, empty, or invalid. "
                  "Replace manifest.json and theme.css now? [y/N]: "
              ).strip().casefold()
              if answer not in {"y", "yes"}:
                  print(f"[SKIP] Theme: repair was not confirmed for {folder_name}")
                  return
              refresh_existing_theme = True
          if not library_type.root.is_dir():
              report_error(f"[FAILED] Theme: library directory does not exist: {library_type.root}")
              return

          try:
              with tempfile.TemporaryDirectory(prefix=".obsidian-library-theme-", dir=library_type.root) as temporary_directory:
                  staging = Path(temporary_directory) / folder_name
                  staging.mkdir()
                  existing_root = destination if destination.exists() else None
                  downloaded = write_theme_source(staging, library_type, repository, source, existing_root)
                  if not theme_core_is_healthy(staging):
                      raise RuntimeError("downloaded theme core is empty or malformed")
                  if existing_root is None:
                      os.replace(staging, destination)
                  else:
                      for filename in downloaded:
                          source_file = staging / filename
                          target = destination / filename
                          target.parent.mkdir(parents=True, exist_ok=True)
                          staged = target.with_name(f".{target.name}.obsidian-library-new")
                          shutil.copyfile(source_file, staged)
                          os.replace(staged, target)
          except (OSError, RuntimeError) as error:
              report_error(f"[FAILED] Theme: {error}")
              return

          action = "REDOWNLOADED" if refresh_existing_theme else "DOWNLOADED"
          print(f"[{action}] Theme: {folder_name} ({source.location}; {', '.join(downloaded)})")


      def repositories_from_list_file(path: Path, library_type: LibraryType) -> list[str]:
          repositories: list[str] = []
          active_section = "all"
          heading_pattern = re.compile(r"^##+\s*(?:Obsidian\s+)?(Plugins|Themes)\s*$", re.IGNORECASE)
          url_pattern = re.compile(
              r"(?i)(?:https?://)?(?:www[.])?github[.]com/[A-Za-z0-9-]+/[A-Za-z0-9_.-]+(?:[.]git)?"
          )

          for line in path.read_text(encoding="utf-8").splitlines():
              heading = heading_pattern.fullmatch(line.strip())
              if heading is not None:
                  active_section = heading.group(1).casefold()
                  continue
              if line.lstrip().startswith("#"):
                  active_section = "none"
                  continue
              if active_section not in {"all", library_type.label.casefold()}:
                  continue
              for value in url_pattern.findall(line):
                  repository = github_repository_from_value(value)
                  if repository not in repositories:
                      repositories.append(repository)

          return repositories


      def repository_from_source_folder(path: Path, library_type: LibraryType) -> str:
          source_manifest = manifest_file(path)
          repository = manifest_repository(path, library_type)
          if repository is not None:
              return repository

          try:
              manifest = json.loads(source_manifest.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError) as error:
              raise RuntimeError(f"{path}: missing a usable manifest repository URL") from error
          if not isinstance(manifest, dict):
              raise RuntimeError(f"{path}: manifest.json does not contain an object")

          identifier = manifest.get("id")
          author = manifest.get("author")
          if isinstance(identifier, str) and re.fullmatch(r"[A-Za-z0-9._-]+", identifier) and \
                  isinstance(author, str) and re.fullmatch(r"[A-Za-z0-9-]+", author):
              return f"{author}/{identifier}"

          raise RuntimeError(f"{path}: could not resolve a GitHub repository from manifest metadata")


      def repositories_from_value(value: str, library_type: LibraryType) -> list[str]:
          path = Path(value).expanduser()
          if path.is_file():
              return repositories_from_list_file(path, library_type)
          if path.is_dir():
              if manifest_file(path).is_file():
                  return [repository_from_source_folder(path, library_type)]
              repositories: list[str] = []
              for child in sorted(path.iterdir(), key=lambda candidate: candidate.name.casefold()):
                  if not child.is_dir() or child.is_symlink() or not manifest_file(child).is_file():
                      continue
                  repository = repository_from_source_folder(child, library_type)
                  if repository not in repositories:
                      repositories.append(repository)
              if repositories:
                  return repositories
              raise RuntimeError(f"{path}: contains no usable plugin or theme source folders")
          return [github_repository_from_value(value)]


      def download_values(
          library_type: LibraryType,
          values: list[str],
          release_cache: dict[str, dict[str, Any] | Exception],
          repository_contents_cache: dict[str, list[dict[str, Any]] | Exception],
      ) -> None:
          BATCH_FAILURES.clear()
          repositories: list[str] = []
          for value in values:
              try:
                  for repository in repositories_from_value(value, library_type):
                      if repository not in repositories:
                          repositories.append(repository)
              except (OSError, RuntimeError) as error:
                  report_error(f"[FAILED] {library_type.label}: {error}")

          for repository in repositories:
              if library_type.is_theme:
                  download_theme(library_type, repository, release_cache, repository_contents_cache)
              else:
                  download_plugin(library_type, repository, release_cache, repository_contents_cache)

          if len(values) > 1 or any(Path(value).is_file() or Path(value).is_dir() for value in values):
              write_batch_failure_report(library_type)


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
          parser.add_argument("--download-plugin", metavar="SOURCE", action="append", help="Download plugin sources: repositories, link lists, or existing folders.")
          parser.add_argument("--download-theme", metavar="SOURCE", action="append", help="Download theme sources: repositories, link lists, or existing folders.")
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
                  download_values(library_types[0], arguments.download_plugin, release_cache, repository_contents_cache)
                  return 0

              if arguments.download_theme:
                  download_values(library_types[1], arguments.download_theme, release_cache, repository_contents_cache)
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
                          download_values(library_types[0], [repository], release_cache, repository_contents_cache)
                      else:
                          print("[SKIP] Plugin: no repository was provided")
                  elif choice == "Download a theme":
                      repository = input("GitHub repository URL or owner/repository: ").strip()
                      if repository:
                          download_values(library_types[1], [repository], release_cache, repository_contents_cache)
                      else:
                          print("[SKIP] Theme: no repository was provided")
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
