# shared/terminal/commands/downloads.nix
#
# =====================================================================
# FISH FUNCTIONS: PORTABLE DOWNLOADS
#
# Portable GitHub, Obsidian-library, and Internet Archive helpers.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ven.features.terminal.fish.downloads;

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;

  legacyTrashCommand =
    if isDarwin then
      ''
        set --local apple_path (
          string replace -a '\\' '\\\\' -- "$legacy_file" |
          string replace -a '"' '\\"'
        )
        if not /usr/bin/osascript \
            -e "tell application \"Finder\" to delete POSIX file \"$apple_path\""
          echo "Notice: Manifest was migrated, but legacy cleanup needs attention: $legacy_file"
          return 1
        end
      ''
    else
      ''
        if not ${pkgs.trash-cli}/bin/trash "$legacy_file"
          echo "Notice: Manifest was migrated, but legacy cleanup needs attention: $legacy_file"
          return 1
        end
      '';
in
{
  options.ven.features.terminal.fish.downloads.enable =
    lib.mkEnableOption "portable Fish download helpers";

  config = lib.mkIf cfg.enable {
    # Linux and NixOS use the pinned trash-cli main program in the safe
    # legacy-file cleanup branch below.
    home.packages = lib.optionals isLinux [ pkgs.trash-cli ];

    programs.fish.functions = {

      # -----------------------------------------------------------------
      # ---- Obsidian -> Shared download rules ---- #
      #
      # Central rules shared by plugin/theme download and repair commands.
      # Blocked names are case-insensitive and match with or without any extension.
      # -----------------------------------------------------------------
      __obsidian_download_name_blocked = {
        description = "Check whether an Obsidian download filename is blocked";

        body = ''
          # ---- BLOCKED BASE NAMES ---- #
          #
          # These names are blocked case-insensitively, with or without any
          # extension.
          set --local blocked_names \
              agents \
              algorithm \
              architecture \
              claude \
              license \
              changelog \
              contributing \
              continent_design \
              continent-design \
              codex_task \
              codex-task \
              decisions \
              design_system \
              design-system \
              implementation_plan \
              implementation-plan \
              manual_test_plan \
              manual-test-plan \
              policies \
              policy \
              security \
              privacy \
              release_checklist \
              release-checklist \
              validation

          # ---- BLOCKED EXACT FILE NAMES ---- #
          #
          # These specific filenames are blocked case-insensitively.
          set --local blocked_files \
              agents.md \
              claude.md \
              list of urls.md \
              main-debug.js \
              publishing.md \
              release.md \
              third_party_notices.md \
              wechat-渐读介绍.md \
              readme_ko.md \
              readme_jp.md \
              readme.zh.md \
              readme.zh-cn.md \
              readme-zh_cn.md \
              readme-zh_tw.md \
              readme-zh.md \
              readme-cn.md \
              readme-tw.md

          # ---- BLOCKED DOCUMENT TITLE STEMS ---- #
          #
          # Strip extensions and separator punctuation before comparing these
          # document titles. This excludes variants such as CODE_OF_CONDUCT.md,
          # Code of Conduct.md, and code-of-conduct.md alike.
          set --local blocked_document_stems \
              aiassistance \
              codeofconduct \
              roadmap \
              readmeakutagawaja \
              readmeja \
              readmesherlock \
              thirdpartynotices

          # ---- FILE NAME ---- #
          set --local filename \
              (string lower -- (basename "$argv[1]"))
          set --local filename_stem \
              (string replace -r '\.[^.]*$' "" -- "$filename")
          set --local normalized_filename_stem \
              (string replace -ra '[^[:alnum:]]+' "" -- "$filename_stem")

          # ---- MATCH BLOCKED DOCUMENT TITLE STEMS ---- #
          if contains "$normalized_filename_stem" $blocked_document_stems
            return 0
          end

          # ---- MATCH BLOCKED BASE NAMES ---- #
          for blocked_name in $blocked_names
            set --local blocked_dot_pattern \
              (string join "" -- "$blocked_name" ".*")
            set --local blocked_hyphen_pattern \
              (string join "" -- "$blocked_name" "-*")
            set --local blocked_underscore_pattern \
              (string join "" -- "$blocked_name" "_*")

            if test "$filename" = "$blocked_name"; or \
                string match -q "$blocked_dot_pattern" "$filename"; or \
                string match -q "$blocked_hyphen_pattern" "$filename"; or \
                string match -q "$blocked_underscore_pattern" "$filename"

              return 0
            end
          end

          # ---- MATCH BLOCKED EXACT FILE NAMES ---- #
          if contains "$filename" $blocked_files
            return 0
          end

          return 1
        '';
      };

      # -----------------------------------------------------------------
      # ---- Obsidian -> Download path rules ---- #
      #
      # Reject localized files and folders before a repository path can be
      # considered for a permanent plugin or theme download.
      # -----------------------------------------------------------------
      __obsidian_download_path_blocked = {
        description = "Check whether an Obsidian download path is blocked";

        body = ''
          set --local download_path "$argv[1]"

          if __obsidian_download_name_blocked (basename "$download_path")
            return 0
          end

          # Locale markers must be a complete filename segment. This keeps
          # ordinary words intact while excluding README_KO.md, docs.zh, and
          # folders named zh, ko, or jp regardless of capitalization.
          for path_part in (string split / -- "$download_path")
            if string match -rqi \
                '(^|[._-])(zh|ko|jp)([._-]|$)' \
                "$path_part"
              return 0
            end
          end

          return 1
        '';
      };

      # -----------------------------------------------------------------
      # ---- Obsidian -> Download layout normalization ---- #
      #
      # Keep compact documentation and preview downloads readable without
      # retaining one-file wrapper folders or image-folder aliases.
      # -----------------------------------------------------------------
      __obsidian_normalize_download_layout = {
        description = "Normalize downloaded Obsidian documentation and image layouts";

        body = ''
          set --local library_entry "$argv[1]"

          if not test -d "$library_entry"; or test -L "$library_entry"
            return 0
          end

          command node -e '
            const fs = require("node:fs");
            const path = require("node:path");
            const root = path.resolve(process.argv[1]);
            const imageExtensions = new Set([".gif", ".jpeg", ".jpg", ".png", ".webp"]);
            const mappings = [];
            const markdownOrigins = new Map();

            function entries(directory) {
              return fs.readdirSync(directory, { withFileTypes: true })
                .filter((entry) => !entry.isSymbolicLink())
                .sort((left, right) => left.name.localeCompare(right.name));
            }

            function filesBelow(directory) {
              const files = [];
              for (const entry of entries(directory)) {
                const candidate = path.join(directory, entry.name);
                if (entry.isDirectory()) files.push(...filesBelow(candidate));
                else if (entry.isFile()) files.push(candidate);
              }
              return files;
            }

            function directoriesBelow(directory) {
              const directories = [];
              for (const entry of entries(directory)) {
                if (!entry.isDirectory()) continue;
                const candidate = path.join(directory, entry.name);
                directories.push(...directoriesBelow(candidate), candidate);
              }
              return directories;
            }

            function rememberMarkdownOrigins(source, destination) {
              const sourceFiles = fs.statSync(source).isDirectory() ? filesBelow(source) : [source];
              for (const sourceFile of sourceFiles) {
                if (path.extname(sourceFile).toLowerCase() !== ".md") continue;
                const relative = fs.statSync(source).isDirectory() ? path.relative(source, sourceFile) : "";
                markdownOrigins.set(path.join(destination, relative), markdownOrigins.get(sourceFile) || sourceFile);
              }
            }

            function move(source, destination) {
              if (fs.existsSync(destination)) return false;
              rememberMarkdownOrigins(source, destination);
              fs.renameSync(source, destination);
              mappings.push([source, destination]);
              return true;
            }

            function isImage(file) {
              return imageExtensions.has(path.extname(file).toLowerCase());
            }

            for (const directory of directoriesBelow(root)) {
              const name = path.basename(directory).toLowerCase();
              const containedFiles = filesBelow(directory);
              const isImageFolder = name === "images";
              const isImageOnlyAf = name === "af" && containedFiles.length > 0 && containedFiles.every(isImage);
              if (!isImageFolder && !isImageOnlyAf) continue;
              move(directory, path.join(path.dirname(directory), "assets"));
            }

            for (const directory of directoriesBelow(root)) {
              const name = path.basename(directory).toLowerCase();
              if (name === "assets" || name === "docs") continue;
              const content = entries(directory);
              if (content.length !== 1 || !content[0].isFile()) continue;
              move(path.join(directory, content[0].name), path.join(path.dirname(directory), content[0].name));
              if (entries(directory).length === 0) fs.rmdirSync(directory);
            }

            const repositoryDirectory = path.join(root, "repo");
            if (fs.existsSync(repositoryDirectory) && fs.statSync(repositoryDirectory).isDirectory()) {
              const repositoryContent = entries(repositoryDirectory);
              const wrapperDirectories = repositoryContent.filter((entry) => entry.isDirectory());
              const wrapperFiles = repositoryContent.filter((entry) => entry.isFile());
              if (wrapperDirectories.length === 1 && wrapperFiles.length > 0 && wrapperFiles.every((entry) => entry.name.toLowerCase().includes("readme"))) {
                const wrapper = path.join(repositoryDirectory, wrapperDirectories[0].name);
                const wrapperContent = entries(wrapper);
                if (wrapperContent.every((entry) => !fs.existsSync(path.join(repositoryDirectory, entry.name)))) {
                  for (const entry of wrapperContent) move(path.join(wrapper, entry.name), path.join(repositoryDirectory, entry.name));
                  fs.rmdirSync(wrapper);
                }
              }

              const finalRepositoryContent = entries(repositoryDirectory);
              if (finalRepositoryContent.length <= 3 && finalRepositoryContent.every((entry) => entry.isFile()) && finalRepositoryContent.every((entry) => !fs.existsSync(path.join(root, entry.name)))) {
                for (const entry of finalRepositoryContent) move(path.join(repositoryDirectory, entry.name), path.join(root, entry.name));
                fs.rmdirSync(repositoryDirectory);
              }
            }

            function remap(source) {
              let current = source;
              for (let changed = true; changed;) {
                changed = false;
                for (const [from, to] of mappings) {
                  if (current === from || current.startsWith(from + path.sep)) {
                    const next = to + current.slice(from.length);
                    if (next !== current) {
                      current = next;
                      changed = true;
                    }
                  }
                }
              }
              return current;
            }

            function rewriteReference(reference, markdownFile) {
              if (/^(?:[a-z]+:|#|\/)/i.test(reference)) return reference;
              const match = reference.match(/^([^?#]*)([?#].*)?$/);
              if (!match || !match[1]) return reference;
              const origin = markdownOrigins.get(markdownFile) || markdownFile;
              const source = path.resolve(path.dirname(origin), match[1]);
              if (source !== root && !source.startsWith(root + path.sep)) return reference;
              const target = remap(source);
              if (target === source) return reference;
              return path.relative(path.dirname(markdownFile), target).split(path.sep).join("/") + (match[2] || "");
            }

            for (const markdownFile of filesBelow(root)) {
              const relative = path.relative(root, markdownFile).split(path.sep);
              const inDocs = relative.slice(0, -1).some((part) => part.toLowerCase() === "docs");
              const isReadme = path.basename(markdownFile).toLowerCase().includes("readme");
              if (!inDocs || path.extname(markdownFile).toLowerCase() !== ".md") {
                if (!isReadme || path.extname(markdownFile).toLowerCase() !== ".md") continue;
              }
              const source = fs.readFileSync(markdownFile, "utf8");
              const rewritten = source
                .replace(/(!\[[^\]]*\]\(\s*<?)([^\s)>]+)(?=[\s)>])/g, (whole, prefix, reference) => prefix + rewriteReference(reference, markdownFile))
                .replace(/(<img\b[^>]*?\bsrc=["\x27])([^"\x27]+)(?=["\x27])/gi, (whole, prefix, reference) => prefix + rewriteReference(reference, markdownFile));
              if (rewritten !== source) fs.writeFileSync(markdownFile, rewritten, "utf8");
            }
          ' "$library_entry"
        '';
      };

      # -----------------------------------------------------------------
      # ---- Obsidian -> Repository fallback names ---- #
      #
      # Remove generic repository suffixes before a repository name is used as
      # the fallback folder name for an Obsidian plugin or theme.
      # -----------------------------------------------------------------
      __obsidian_repository_fallback_name = {
        description = "Clean an Obsidian repository fallback folder name";

        body = ''
          set --local repository_name "$argv[1]"
          set --local fallback_name "$repository_name"

          # ---- GENERIC REPOSITORY SUFFIXES ---- #
          set --local generic_names \
              main \
              manifest \
              master \
              repo \
              dotfiles \
              dots

          # ---- REMOVE GENERIC SUFFIXES ---- #
          while test -n "$fallback_name"
            set --local previous_name "$fallback_name"

            for generic_name in $generic_names
              set fallback_name (
                string replace -r \
                  "(?i)[-_ ]$generic_name\$" \
                  "" \
                  "$fallback_name"
              )

              if test "$fallback_name" != "$previous_name"
                set fallback_name \
                  (string trim --chars='-_ ' "$fallback_name")
                break
              end
            end

            if test "$fallback_name" = "$previous_name"
              break
            end
          end

          # ---- REJECT GENERIC-ONLY NAMES ---- #
          for generic_name in $generic_names
            if test (string lower -- "$fallback_name") = "$generic_name"
              return 1
            end
          end

          if test -z "$fallback_name"
            return 1
          end

          printf '%s\n' "$fallback_name"
        '';
      };

      # -----------------------------------------------------------------
      # ---- Obsidian -> Named release archives ---- #
      #
      # A release may include a plugin/theme distribution archive named after
      # the library itself. A matching ZIP is a last-resort core-payload
      # fallback; matching tarballs are source-style archives and stay skipped.
      # -----------------------------------------------------------------
      __obsidian_is_named_release_archive = {
        description = "Check whether a release archive is named after an Obsidian library";

        body = ''
          set --local asset_name "$argv[1]"
          set --local library_names $argv[2..-1]

          if not string match -rqi '\\.(zip|tar\\.gz|tgz)$' "$asset_name"
            return 1
          end

          set --local normalized_asset_name (
            string replace -ri '\\.(zip|tar\\.gz|tgz)$' "" -- "$asset_name" |
            string lower |
            string replace -ra '[^0-9a-z]+' ""
          )

          for library_name in $library_names
            set --local normalized_library_name (
              string lower -- "$library_name" |
              string replace -ra '[^0-9a-z]+' ""
            )

            if test -z "$normalized_library_name"
              continue
            end

            if string match -rq \
                "$normalized_library_name" \
                "$normalized_asset_name"
              return 0
            end
          end

          return 1
        '';
      };

      # -----------------------------------------------------------------
      # ---- gitdll -> Download Git repositories or rebuild Obsidian libraries ---- #
      #
      # Existing repository download modes:
      # gitdll "https://github.com/owner/repository"
      # gitdll "https://github.com/owner/one" "https://github.com/owner/two"
      # gitdll links.txt
      #
      # Obsidian download modes:
      # gitdll --plugin "https://github.com/owner/plugin" [...]
      # gitdll --theme links.txt [...]
      # gitdll-plugins "https://github.com/owner/plugin" [...]
      # gitdll-themes links.txt [...]
      #
      # In the Obsidian modes, source directories are checked one level deep.
      # A saved manifest URL is reused immediately. When it is absent, gitdll
      # resolves only matching repository metadata; the downloaded manifest is
      # the sole place where the resolved URL is retained.
      # -----------------------------------------------------------------
      gitdll = {
        description = "Download Git repositories, Obsidian plugins, or Obsidian themes";

        body = ''
          if test (count $argv) -gt 0; and \
              contains -- "$argv[1]" --plugin --plugins --theme --themes

            set --local mode "$argv[1]"

            # Accept singular and plural mode flags, while keeping one internal
            # representation for the rest of the downloader.
            if test "$mode" = "--plugin"
              set mode --plugins
            else if test "$mode" = "--theme"
              set mode --themes
            end
            set --local source_inputs
            set --local include_paths
            set --local include_list_files
            set --local destination
            set --local argument_index 2

            while test "$argument_index" -le (count $argv)
              switch "$argv[$argument_index]"
                case --to
                  set argument_index (
                    math "$argument_index + 1"
                  )

                  if test "$argument_index" -gt (count $argv)
                    echo "Error: --to requires a destination path."
                    return 1
                  end

                  set destination "$argv[$argument_index]"

                case --include
                  set argument_index (math "$argument_index + 1")
                  if test "$argument_index" -gt (count $argv)
                    echo "Error: --include requires a repository-relative path."
                    return 1
                  end
                  set --append include_paths "$argv[$argument_index]"

                case --include-file
                  set argument_index (math "$argument_index + 1")
                  if test "$argument_index" -gt (count $argv)
                    echo "Error: --include-file requires a path-list file."
                    return 1
                  end
                  set --append include_list_files "$argv[$argument_index]"

                case '--*'
                  echo "Error: Unknown option:"
                  echo "  $argv[$argument_index]"
                  return 1

                case '*'
                  set --append source_inputs "$argv[$argument_index]"
              end

              set argument_index (
                math "$argument_index + 1"
              )
            end

            if test (count $source_inputs) -eq 0
              echo "Error: At least one repository URL, source folder, or link file is required."
              echo
              echo "Usage:"
              echo '  gitdll --plugin "https://github.com/owner/plugin" [...]'
              echo '  gitdll --theme links.txt [...]'
              return 1
            end

            for include_list_file in $include_list_files
              if not test -f "$include_list_file"
                echo "Error: Include list does not exist: $include_list_file"
                return 1
              end
              while read --local include_line
                set include_line (string trim "$include_line")
                if test -n "$include_line"; and not string match -q '#*' "$include_line"
                  set --append include_paths "$include_line"
                end
              end <"$include_list_file"
            end

            for include_path in $include_paths
              if string match -rq '(^|/)\.\.(/|$)|^/' "$include_path"; or test -z "$include_path"
                echo "Error: Unsafe include path: $include_path"
                return 1
              end
            end

            for source_input in $source_inputs
              if not test -d "$source_input"; and not test -f "$source_input"; and \
                  not string match -rq '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' "$source_input"; and \
                  not string match -rq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$source_input"
                echo "Error: Repository URL, source directory, or link file does not exist:"
                echo "  $source_input"
                return 1
              end
            end

            # Keep selected downloader settings outside the mode conditional.
            set --local library_type
            set --local downloader_function
            set --local manifest_url_field
            set --local failed_report_name

            if test "$mode" = "--plugins"
              if not functions -q __gitdll_plugins
                echo "Error: the plugin downloader is not available."
                return 1
              end

              set library_type plugins
              set downloader_function __gitdll_plugins
              set manifest_url_field pluginUrl
              set failed_report_name \
                failed-plugin-downloads.txt
              if test -z "$destination"
                set destination "$HOME/Downloads/gitdll-plugins"
              end
            else
              if not functions -q __gitdll_themes
                echo "Error: the theme downloader is not available."
                return 1
              end

              set library_type themes
              set downloader_function __gitdll_themes
              set manifest_url_field themeUrl
              set failed_report_name \
                failed-theme-downloads.txt
              if test -z "$destination"
                set destination "$HOME/Downloads/gitdll-themes"
              end
            end

            command mkdir -p -- "$destination"
            or begin
              echo "Error: Could not create destination folder:"
              echo "  $destination"
              return 1
            end

            set --local temporary_directory (
              command mktemp -d \
                "$TMPDIR/gitdll-library.XXXXXXXXXX"
            )

            if test -z "$temporary_directory"
              echo "Error: Could not create a temporary directory."
              return 1
            end

            set --local repositories_file \
              "$temporary_directory/repositories.txt"

            set --local source_map_file \
              "$temporary_directory/source-map.tsv"

            set --local missing_file \
              "$temporary_directory/missing.txt"

            set --local failed_file \
              "$temporary_directory/failed.txt"

            set --local failed_report \
              "$destination/$failed_report_name"

            set --local function_file \
              "$temporary_directory/downloader.fish"

            set --local downloader_temporary_directory \
              "$destination/.gitdll-tmp"

            command mkdir -p -- "$downloader_temporary_directory"

            command touch \
              "$repositories_file" \
              "$source_map_file" \
              "$missing_file" \
              "$failed_file"

            function __gitdll_write_failure_report \
                --no-scope-shadowing

              set --local staged_report "$temporary_directory/failed-report.txt"
              command cat "$missing_file" "$failed_file" | \
                command sort -u >"$staged_report"

              if test -s "$staged_report"
                command mv -- "$staged_report" "$failed_report"
              else
                command rm -f -- "$staged_report" "$failed_report"
              end
            end

            functions \
              __obsidian_download_name_blocked \
              __obsidian_download_path_blocked \
              __obsidian_normalize_download_layout \
              __obsidian_repository_fallback_name \
              __obsidian_is_named_release_archive \
              "$downloader_function" \
              >"$function_file"

            if not test -s "$function_file"
              echo "Error: Could not export $downloader_function."
              command rm -rf -- "$temporary_directory"
              return 1
            end

            set --local source_count 0
            set --local repository_count 0
            set --local missing_count 0

            # Check only the small files that establish a usable plugin/theme.
            # This establishes that the manifest-derived direct path is usable;
            # identity comparison is reserved for fallback repository discovery.
            function __gitdll_required_files_exist \
                --argument-names candidate library_type

              # A current release is the authoritative install source. Resolve
              # each required file from it first, then ask the repository only
              # for the individual files the release does not ship.
              set --local release_assets (
                command gh api \
                  "repos/$candidate/releases/latest" \
                  --jq '.assets[]? | [.name, .browser_download_url] | @tsv' \
                  2>/dev/null
              )
              set --local manifest_url
              set --local payload_url

              for release_asset in $release_assets
                set --local release_parts (string split \t "$release_asset")
                if test (count $release_parts) -lt 2
                  continue
                end

                switch "$release_parts[1]"
                  case manifest.json
                    set manifest_url "$release_parts[2]"
                  case main.js
                    if test "$library_type" = plugins
                      set payload_url "$release_parts[2]"
                    end
                  case theme.css obsidian.css
                    if test "$library_type" = themes; and test -z "$payload_url"
                      set payload_url "$release_parts[2]"
                    end
                end
              end

              if test -z "$manifest_url"
                set manifest_url (
                  command gh api \
                    "repos/$candidate/contents/manifest.json" \
                    --jq .download_url \
                    2>/dev/null
                )
              end

              if test -z "$payload_url"
                if test "$library_type" = plugins
                  set payload_url (
                    command gh api \
                      "repos/$candidate/contents/main.js" \
                      --jq .download_url \
                      2>/dev/null
                  )
                else
                  for payload_name in theme.css obsidian.css
                    set payload_url (
                      command gh api \
                        "repos/$candidate/contents/$payload_name" \
                        --jq .download_url \
                        2>/dev/null
                    )

                    if test -n "$payload_url"
                      break
                    end
                  end
                end
              end

              test -n "$manifest_url"; and test -n "$payload_url"
            end

            # Compare a remote manifest only in the fallback path. JSON parsing
            # ignores indentation and formatting; only id and author matter.
            function __gitdll_remote_matches \
                --argument-names candidate library_id library_author library_type

              set --local release_manifest_url (
                command gh api \
                  "repos/$candidate/releases/latest" \
                  --jq '.assets[]? | select(.name == "manifest.json") | .browser_download_url' \
                  2>/dev/null |
                command head -n 1
              )
              set --local remote_manifest

              if test -n "$release_manifest_url"
                set remote_manifest (
                  command curl --fail --location --silent --show-error \
                    "$release_manifest_url" 2>/dev/null
                )
              else
                set remote_manifest (
                  command gh api \
                    "repos/$candidate/contents/manifest.json" \
                    --jq .content \
                    2>/dev/null |
                  command tr -d '\n' |
                  command base64 -D 2>/dev/null
                )
              end

              if test -z "$remote_manifest"
                return 1
              end

              set --local remote_id (
                printf '%s' "$remote_manifest" |
                command jq -r \
                  'if (.id | type) == "string" then .id else empty end' \
                  2>/dev/null |
                string trim
              )

              set --local remote_author (
                printf '%s' "$remote_manifest" |
                command jq -r \
                  'if (.author | type) == "string" then .author else empty end' \
                  2>/dev/null |
                string trim
              )

              set --local normalized_library_id (
                string lower -- "$library_id" |
                string replace -ra '[^a-z0-9]' '''
              )

              set --local normalized_remote_id (
                string lower -- "$remote_id" |
                string replace -ra '[^a-z0-9]' '''
              )

              if test -z "$normalized_library_id"; or \
                  test "$normalized_library_id" != "$normalized_remote_id"
                return 1
              end

              if test -n "$library_author"
                set --local normalized_library_author (
                  string lower -- "$library_author" |
                  string replace -ra '[^a-z0-9]' '''
                )

                set --local normalized_remote_author (
                  string lower -- "$remote_author" |
                  string replace -ra '[^a-z0-9]' '''
                )

                if test -z "$normalized_remote_author"; or \
                    test "$normalized_library_author" != "$normalized_remote_author"
                  return 1
                end
              end

              __gitdll_required_files_exist "$candidate" "$library_type"
            end

            function __gitdll_resolve_repository \
                --argument-names source_folder library_type

              if not command -q gh; or not command -q jq; or \
                  not command -q base64
                echo "Error: resolving repository URLs requires gh, jq, and base64." >&2
                return 1
              end

              set --local manifest_file "$source_folder/manifest.json"

              if not test -f "$manifest_file"
                set manifest_file "$source_folder/repo/manifest.json"
              end

              if not test -f "$manifest_file"; or \
                  not command jq -e . "$manifest_file" >/dev/null 2>&1
                return 1
              end

              set --local library_id (
                command jq -r \
                  'if (.id | type) == "string" then .id else empty end' \
                  "$manifest_file" |
                string trim
              )

              set --local library_author (
                command jq -r \
                  'if (.author | type) == "string" then .author else empty end' \
                  "$manifest_file" |
                string trim
              )

              set --local author_url (
                command jq -r \
                  'if (.authorUrl | type) == "string" then .authorUrl else empty end' \
                  "$manifest_file" |
                string trim
              )

              if test -z "$library_id"; or \
                  not string match -rq '^[A-Za-z0-9._-]+$' "$library_id"
                return 1
              end

              set --local author_url_owner (
                string match -r --groups-only \
                  '^https?://github\\.com/([^/]+)/?' \
                  -- "$author_url"
              )

              set --local direct_owners

              if string match -rq '^[A-Za-z0-9-]+$' "$library_author"
                set --append direct_owners "$library_author"
              end

              if string match -rq '^[A-Za-z0-9-]+$' "$author_url_owner"; and \
                  not contains -- "$author_url_owner" $direct_owners
                set --append direct_owners "$author_url_owner"
              end

              # Do exactly what the manifest describes before considering any
              # alternatives: author/id, then authorUrl owner/id. If this direct
              # path contains the required files, use it immediately. Remote
              # manifest comparison is the fallback for different repo names.
              for direct_owner in $direct_owners
                set --local direct_candidate "$direct_owner/$library_id"

                if __gitdll_required_files_exist \
                    "$direct_candidate" \
                    "$library_type"
                  echo "https://github.com/$direct_candidate"
                  return 0
                end
              end

              # Only the exact manifest author may supply fallback candidates.
              set --local fallback_owner "$library_author"

              if not string match -rq '^[A-Za-z0-9-]+$' "$fallback_owner"
                set fallback_owner "$author_url_owner"
              end

              if not string match -rq '^[A-Za-z0-9-]+$' "$fallback_owner"
                return 1
              end

              set --local candidates (
                command gh api \
                  "users/$fallback_owner/repos?per_page=100&type=owner" \
                  --jq '.[] | select(.archived | not) | .full_name' \
                  2>/dev/null
              )

              set --local matches

              for candidate in $candidates
                if __gitdll_remote_matches \
                    "$candidate" \
                    "$library_id" \
                    "$library_author" \
                    "$library_type"
                  set --append matches "$candidate"
                end
              end

              if test (count $matches) -eq 1
                echo "https://github.com/$matches[1]"
                return 0
              end

              if test (count $matches) -lt 2
                return 1
              end

              echo "Choose a repository for "(basename "$source_folder")":" >&2
              set --local candidate_index 1

              for candidate in $matches
                echo "  $candidate_index) https://github.com/$candidate" >&2
                set candidate_index (math "$candidate_index + 1")
              end

              read --prompt-str "Choose a repository number, or s to skip: " selection

              if test "$selection" = s; or test "$selection" = S; or \
                  not string match -rq '^[0-9]+$' "$selection"; or \
                  test "$selection" -lt 1; or \
                  test "$selection" -gt (count $matches)
                return 1
              end

              echo "https://github.com/$matches[$selection]"
            end

            for source_input in $source_inputs
              set --local inline_repository_url (
                string match -r -m 1 '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' "$source_input"
              )

              if test -z "$inline_repository_url"; and \
                  string match -rq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$source_input"
                set inline_repository_url "https://$source_input"
              end

              if test -n "$inline_repository_url"
                set --local repository_url (
                  string trim -- "$inline_repository_url"
                )

                if not string match -rq '^https?://' "$repository_url"
                  set repository_url "https://$repository_url"
                end

                set repository_url (
                  string replace -r '^https?://www\\.' 'https://' "$repository_url" |
                  string replace -r '\\.git/?$' ''' |
                  string replace -r '/$' '''
                )

                printf '%s\n' "$repository_url" >>"$repositories_file"
                printf '%s\t%s\n' "$source_input" "$repository_url" >>"$source_map_file"
                set source_count (math "$source_count + 1")
                set repository_count (math "$repository_count + 1")
                continue
              end

              if test -f "$source_input"
                set --local source_name (
                  basename "$source_input"
                )
                set --local active_section all

                while read --local line
                  # A list may use Markdown headings, blank lines, or
                  # angle-bracket links. In a named section, retain only URLs for
                  # the selected library type; unsectioned lists keep every URL.
                  set --local section_heading (
                    string match -r -i -g '^##+[[:space:]]*(?:Obsidian[[:space:]]+)?(Plugins|Themes)[[:space:]]*$' "$line" |
                    string lower
                  )

                  if test -n "$section_heading"
                    set active_section "$section_heading"
                    continue
                  end

                  if string match -rq '^##+' "$line"
                    set active_section none
                    continue
                  end

                  if test "$active_section" != all; and test "$active_section" != "$library_type"
                    continue
                  end

                  for repository_url in (string match -r -a '(?i)(?:https?://)?(?:www\.)?github\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\.git)?' "$line")

                  if not string match -rq '^https?://' "$repository_url"
                    set repository_url "https://$repository_url"
                  end

                  set repository_url (
                    string replace -r '^https?://www\.' 'https://' "$repository_url"
                  )

                  set source_count (
                    math "$source_count + 1"
                  )

                  set repository_url (
                    string replace -r \
                      '\\.git/?$' \
                      ''' \
                      "$repository_url"
                  )

                  set repository_url (
                    string replace -r \
                      '/$' \
                      ''' \
                      "$repository_url"
                  )

                  if not string match -rq \
                      '^https?://github\\.com/[^/]+/[^/]+$' \
                      "$repository_url"

                    printf '%s\t%s\n' \
                      "$source_name" \
                      "$repository_url" \
                      >>"$missing_file"

                    set missing_count (
                      math "$missing_count + 1"
                    )

                    continue
                  end

                  printf '%s\n' \
                    "$repository_url" \
                    >>"$repositories_file"

                  printf '%s\t%s\n' \
                    "$repository_url" \
                    "$repository_url" \
                    >>"$source_map_file"

                  set repository_count (
                    math "$repository_count + 1"
                  )
                  end
                end <"$source_input"

                continue
              end

              for source_folder in "$source_input"/*
                if not test -d "$source_folder"
                  continue
                end

              set source_count (
                math "$source_count + 1"
              )

              set --local source_name (
                basename "$source_folder"
              )

              set --local repository_file \
                "$source_folder/repository-url.txt"

              if not test -f "$repository_file"
                set repository_file \
                  "$source_folder/repo/repository-url.txt"
              end

              set --local repository_url

              if test -f "$repository_file"
                set repository_url (
                  string match -r -m 1 '(?i)(?:https?://)?(?:www\.)?github\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\.git)?' <"$repository_file" |
                  string trim
                )
              end

              if test -n "$repository_url"; and \
                  not string match -rq \
                    '^https?://github\\.com/[^/]+/[^/]+/?$' \
                    "$repository_url"
                set repository_url
              end

              if test -z "$repository_url"
                set repository_url (
                  __gitdll_resolve_repository "$source_folder" "$library_type"
                )
              end

              set repository_url (
                string replace -r \
                  '\.git/?$' \
                  ''' \
                  "$repository_url"
              )

              set repository_url (
                string replace -r \
                  '/$' \
                  ''' \
                  "$repository_url"
              )

              if not string match -rq \
                  '^https?://github\.com/[^/]+/[^/]+$' \
                  "$repository_url"

                printf '%s — missing or invalid repository-url.txt\n' \
                  "$source_name" \
                  >>"$missing_file"

                set missing_count (
                  math "$missing_count + 1"
                )

                continue
              end

              printf '%s\n' \
                "$repository_url" \
                >>"$repositories_file"

              printf '%s\t%s\n' \
                "$source_name" \
                "$repository_url" \
                >>"$source_map_file"

              set repository_count (
                math "$repository_count + 1"
              )
              end
            end

            if test "$repository_count" -eq 0
              __gitdll_write_failure_report

              functions -e __gitdll_write_failure_report
              echo "Failed. Details: $failed_report"
              command rm -rf -- "$temporary_directory"
              command rm -rf -- "$downloader_temporary_directory"

              return 1
            end

            env \
              TMPDIR="$downloader_temporary_directory" \
              fish \
              --no-config \
              --command '
                source "$argv[1]"
                $argv[2] "$argv[3]" --to "$argv[4]"
              ' \
              "$function_file" \
              "$downloader_function" \
              "$repositories_file" \
              "$destination" \
              2>&1 | tee "$temporary_directory/downloader.log"

            set --local downloader_status $pipestatus[1]

            function __gitdll_download_includes \
                --argument-names repository_url destination_directory

              if test (count $include_paths) -eq 0
                return 0
              end

              set --local repository_name (
                string replace -r '^https://github\\.com/' "" -- "$repository_url"
              )
              set --local repository_files (
                command gh api \
                  "repos/$repository_name/git/trees/HEAD?recursive=1" \
                  --jq '.tree[]? | select(.type == "blob") | .path' \
                  2>/dev/null
              )
              if test $status -ne 0
                printf '%s — could not inspect repository paths for includes\n' "$repository_url" >>"$failed_file"
                return 1
              end

              for include_path in $include_paths
                set --local matched_paths (
                  printf '%s\n' $repository_files | \
                    command awk -v requested="$include_path" '$0 == requested || index($0, requested "/") == 1'
                )
                if test (count $matched_paths) -eq 0
                  printf '%s — requested path not found: %s\n' "$repository_url" "$include_path" >>"$failed_file"
                  continue
                end
                for repository_path in $matched_paths
                  set --local destination_file "$destination_directory/$repository_path"
                  if test -L "$destination_file"
                    printf '%s — refusing to replace symlinked include: %s\n' "$repository_url" "$repository_path" >>"$failed_file"
                    continue
                  end
                  if test -s "$destination_file"
                    continue
                  end
                  command mkdir -p (dirname "$destination_file")
                  set --local download_url (
                    command gh api \
                      "repos/$repository_name/contents/$repository_path" \
                      --jq .download_url \
                      2>/dev/null
                  )
                  if test -z "$download_url"; or not command curl \
                      --fail --location --silent --show-error \
                      --output "$destination_file" "$download_url"
                    command rm -f -- "$destination_file"
                    printf '%s — could not download requested path: %s\n' "$repository_url" "$repository_path" >>"$failed_file"
                  end
                end
              end
            end

            set --local downloaded_count 0

            while read --local source_mapping
              if test -z "$source_mapping"
                continue
              end

              set --local mapping_parts (
                string split \t "$source_mapping"
              )

              if test (count $mapping_parts) -lt 2
                continue
              end

              set --local original_name \
                "$mapping_parts[1]"

              set --local original_url \
                "$mapping_parts[2]"

              set --local matching_manifest_file
              for manifest_candidate in (command find "$destination" \
                  -mindepth 2 \
                  -maxdepth 2 \
                  -type f \
                  -name manifest.json \
                  -print 2>/dev/null)
                if command jq -e \
                    --arg field "$manifest_url_field" \
                    --arg url "$original_url" \
                    '.[$field] == $url' \
                    "$manifest_candidate" \
                    >/dev/null 2>&1
                  set matching_manifest_file "$manifest_candidate"
                  break
                end
              end

              if test -z "$matching_manifest_file"
                set --local repository_name (
                  string replace -r '^https://github\\.com/' "" -- "$original_url"
                )
                if command gh api "repos/$repository_name" >/dev/null 2>&1
                  printf '%s — no compatible %s files were downloaded\n' \
                    "$original_name" \
                    "$library_type" \
                    >>"$failed_file"
                else
                  printf '%s — repository unavailable (wrong URL, private repository, or connection error)\n' \
                    "$original_name" \
                    >>"$failed_file"
                end
              else
                __gitdll_download_includes \
                  "$original_url" \
                  (dirname "$matching_manifest_file")
                set downloaded_count (
                  math "$downloaded_count + 1"
                )
              end
            end <"$source_map_file"

            if test "$downloader_status" -ne 0; and not test -s "$failed_file"
              echo "The downloader stopped before reporting a specific reason" >>"$failed_file"
            end

            set --local failed_count (
              command wc -l \
                <"$failed_file" |
              string trim
            )

            __gitdll_write_failure_report

            command rm -rf -- "$temporary_directory"
            command rm -rf -- "$downloader_temporary_directory"

            functions -e __gitdll_write_failure_report
            functions -e __gitdll_download_includes

            if test "$downloader_status" -ne 0; or test "$missing_count" -gt 0; or \
                test "$failed_count" -gt 0
              echo "Failed. Details: $failed_report"
              return 1
            end

            echo "Successful"
            return 0
          end

          set --local destination "$HOME/Downloads/gitdll"

          # Generic partial-download mode: `gitdll REPOSITORY --include path`.
          # It fetches individual GitHub blobs and never clones or archives a repo.
          if contains -- --include $argv; or contains -- --include-file $argv
            set --local generic_repositories
            set --local generic_includes
            set --local generic_index 1
            while test "$generic_index" -le (count $argv)
              switch "$argv[$generic_index]"
                case --include
                  set generic_index (math "$generic_index + 1")
                  if test "$generic_index" -gt (count $argv)
                    echo "Error: --include requires a path."
                    return 1
                  end
                  set --append generic_includes "$argv[$generic_index]"
                case --include-file
                  set generic_index (math "$generic_index + 1")
                  if test "$generic_index" -gt (count $argv); or not test -f "$argv[$generic_index]"
                    echo "Error: --include-file requires an existing path-list file."
                    return 1
                  end
                  while read --local generic_line
                    set generic_line (string trim "$generic_line")
                    if test -n "$generic_line"; and not string match -q '#*' "$generic_line"
                      set --append generic_includes "$generic_line"
                    end
                  end <"$argv[$generic_index]"
                case '*'
                  set --append generic_repositories "$argv[$generic_index]"
              end
              set generic_index (math "$generic_index + 1")
            end
            if test (count $generic_repositories) -ne 1; or test (count $generic_includes) -eq 0
              echo "Usage: gitdll REPOSITORY --include path [--include path | --include-file paths.txt]"
              return 1
            end
            set --local generic_repository (
              string replace -r '^https?://github\\.com/' "" -- "$generic_repositories[1]" |
              string replace -r '\\.git/?$' "" |
              string trim --chars=/
            )
            if not string match -rq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$generic_repository"
              echo "Error: Generic includes require one GitHub owner/repository URL."
              return 1
            end
            if not command -q gh; or not command -q curl
              echo "Error: Generic includes require gh and curl."
              return 1
            end
            set --local generic_destination "$destination/"(basename "$generic_repository")
            command mkdir -p -- "$generic_destination"
            set --local generic_files (command gh api "repos/$generic_repository/git/trees/HEAD?recursive=1" --jq '.tree[]? | select(.type == "blob") | .path' 2>/dev/null)
            for generic_include in $generic_includes
              if string match -rq '(^|/)\.\.(/|$)|^/' "$generic_include"
                echo "Error: Unsafe include path: $generic_include"
                return 1
              end
              set --local generic_matches (printf '%s\n' $generic_files | command awk -v requested="$generic_include" '$0 == requested || index($0, requested "/") == 1')
              if test (count $generic_matches) -eq 0
                echo "Error: Requested path not found: $generic_include"
                return 1
              end
              for generic_file in $generic_matches
                set --local generic_url (command gh api "repos/$generic_repository/contents/$generic_file" --jq .download_url 2>/dev/null)
                set --local generic_target "$generic_destination/$generic_file"
                command mkdir -p (dirname "$generic_target")
                if not command curl --fail --location --silent --show-error --output "$generic_target" "$generic_url"
                  command rm -f -- "$generic_target"
                  echo "Error: Could not download $generic_file"
                  return 1
                end
              end
            end
            echo "Successful"
            return 0
          end

          if test (count $argv) -eq 0
            echo "Usage:"
            echo '  gitdll "https://github.com/owner/repository" [...]'
            echo "  gitdll <links.txt> [more-links-or-files ...]"
            echo
            echo "Obsidian library modes:"
            echo '  gitdll --plugin "https://github.com/owner/plugin" [...]'
            echo '  gitdll --theme links.txt [...]'
            return 1
          end

          if not command -q git
            echo "Error: git is not installed."
            return 1
          end

          set --local repositories

          for source in $argv
            if test -f "$source"
              while read --local line
                set line (string trim "$line")

                if test -z "$line"
                  continue
                end

                if string match -q '#*' "$line"
                  continue
                end

                set line (string trim --chars='<> ' "$line")
                set --append repositories "$line"
              end <"$source"
            else
              set --append repositories "$source"
            end
          end

          if test (count $repositories) -eq 0
            echo "Error: No repository links were found."
            return 1
          end

          command mkdir -p -- "$destination"
          or begin
            echo "Error: Could not create destination:"
            echo "  $destination"
            return 1
          end

          set --local failed 0

          for repository_url in $repositories
            set --local cleaned_url (
              string replace -r '/$' ''' "$repository_url"
            )

            set --local repository_name (
              basename "$cleaned_url"
            )

            set repository_name (
              string replace -r '\.git$' ''' "$repository_name"
            )

            if test -z "$repository_name"
              echo
              echo "Skipping invalid repository link:"
              echo "  $repository_url"
              set failed 1
              continue
            end

            if test "$repository_name" = "."
              echo
              echo "Skipping invalid repository link:"
              echo "  $repository_url"
              set failed 1
              continue
            end

            if test "$repository_name" = ".."
              echo
              echo "Skipping invalid repository link:"
              echo "  $repository_url"
              set failed 1
              continue
            end

            set --local repository_directory \
              "$destination/$repository_name"

            if test -e "$repository_directory"; or test -L "$repository_directory"
              echo
              echo "Skipping:"
              echo "  $repository_directory"
              echo "Reason: destination already exists."
              set failed 1
              continue
            end

            echo
            echo "Downloading repository:"
            echo "  $repository_url"

            if command git clone \
                --recurse-submodules \
                -- \
                "$repository_url" \
                "$repository_directory"

              echo "Saved:"
              echo "  $repository_directory"
            else
              echo "Error: Could not download repository:"
              echo "  $repository_url"

              command rm -rf -- "$repository_directory"

              set failed 1
            end
          end

          return $failed
        '';
      };
      # -----------------------------------------------------------------

      # -----------------------------------------------------------------
      # ---- __gitdll_plugins -> Internal Obsidian plugin downloader ---- #
      # -----------------------------------------------------------------
      __gitdll_plugins = {
        description = "Download Obsidian plugin release files and repository metadata";

        body = ''
          # Parse repository URLs and an optional destination path.
          set --local destination "$HOME/Downloads/gitdll-plugins"
          set --local repository_inputs
          set --local expecting_destination 0

          if test (count $argv) -eq 0
              echo "Usage:"
              echo '  gitdll-plugins <links.txt>'
              echo '  gitdll-plugins "https://github.com/owner/repository" [...]'
              echo '  gitdll-plugins <links.txt-or-repository-url> [...] --to "destination path"'
              return 1
          end

          for argument in $argv
              switch "$argument"
                  case --to
                      if test "$expecting_destination" -eq 1
                          echo "Error: --to requires a destination path."
                          return 1
                      end

                      set expecting_destination 1

                  case '--*'
                      echo "Error: Unknown option:"
                      echo "  $argument"
                      return 1

                  case '*'
                      if test "$expecting_destination" -eq 1
                          set destination "$argument"
                          set expecting_destination 0
                      else
                          set repository_inputs $repository_inputs "$argument"
                      end
              end
          end

          if test "$expecting_destination" -eq 1
              echo "Error: --to requires a destination path."
              return 1
          end

          if not command -q gh
              echo "Error: gh is not installed."
              return 1
          end

          if not command -q node
              echo "Error: node is not installed."
              return 1
          end

          function __gitdll_plugin_stylesheet_is_healthy --argument-names stylesheet_file
              if not test -f "$stylesheet_file"; or not test -s "$stylesheet_file"
                  return 1
              end
              command node -e '
                const source = require("node:fs").readFileSync(process.argv[1], "utf8");
                let depth = 0, quote = "", escaped = false, comment = false;
                for (let index = 0; index < source.length; index += 1) {
                  const character = source[index], next = source[index + 1] || "";
                  if (comment) { if (character === "*" && next === "/") { comment = false; index += 1; } continue; }
                  if (quote) { if (escaped) escaped = false; else if (character === "\\\\") escaped = true; else if (character === quote) quote = ""; continue; }
                  if (character === "/" && next === "*") { comment = true; index += 1; }
                  else if (character === "\"") quote = character;
                  else if (character === "{") depth += 1;
                  else if (character === "}") { depth -= 1; if (depth < 0) process.exit(1); }
                }
                if (comment || quote || depth !== 0) process.exit(1);
              ' "$stylesheet_file" >/dev/null 2>&1
          end

          if not command -q jq
              echo "Error: jq is not installed."
              return 1
          end

          if not command -q node
              echo "Error: node is not installed."
              return 1
          end

          function __gitdll_plugin_core_is_healthy --argument-names plugin_directory
              if not test -r "$plugin_directory/manifest.json"; or \
                  not test -s "$plugin_directory/manifest.json"; or \
                  not command jq -e 'type == "object"' "$plugin_directory/manifest.json" >/dev/null 2>&1; or \
                  not test -r "$plugin_directory/main.js"; or \
                  not test -s "$plugin_directory/main.js"; or \
                  not command node --check "$plugin_directory/main.js" >/dev/null 2>&1
                  return 1
              end

              if test -e "$plugin_directory/styles.css"
                  if not test -s "$plugin_directory/styles.css"; or \
                      not command node -e '
                        const source = require("node:fs").readFileSync(process.argv[1], "utf8");
                        let depth = 0, quote = "", escaped = false, comment = false;
                        for (let index = 0; index < source.length; index += 1) {
                          const character = source[index], next = source[index + 1] || "";
                          if (comment) { if (character === "*" && next === "/") { comment = false; index += 1; } continue; }
                          if (quote) { if (escaped) escaped = false; else if (character === "\\\\") escaped = true; else if (character === quote) quote = ""; continue; }
                          if (character === "/" && next === "*") { comment = true; index += 1; }
                          else if (character === "\"") quote = character;
                          else if (character === "{") depth += 1;
                          else if (character === "}") { depth -= 1; if (depth < 0) process.exit(1); }
                        }
                        if (comment || quote || depth !== 0) process.exit(1);
                      ' "$plugin_directory/styles.css" >/dev/null 2>&1
                      return 1
                  end
              end

              return 0
          end

          function __gitdll_plugin_payload_is_healthy --argument-names plugin_directory
              if not test -r "$plugin_directory/manifest.json"; or \
                  not test -s "$plugin_directory/manifest.json"; or \
                  not command jq -e 'type == "object"' "$plugin_directory/manifest.json" >/dev/null 2>&1; or \
                  not test -r "$plugin_directory/main.js"; or \
                  not test -s "$plugin_directory/main.js"; or \
                  not command node --check "$plugin_directory/main.js" >/dev/null 2>&1
                  return 1
              end

              return 0
          end

          function __gitdll_replace_plugin_core_from_url --argument-names destination_file download_url
              set --local staging_file "$destination_file.gitdll-new"
              command rm -f -- "$staging_file"
              if command curl --fail --location --silent --show-error \
                      --output "$staging_file" "$download_url"; and \
                  test -s "$staging_file"
                  command mv -- "$staging_file" "$destination_file"
                  return $status
              end
              command rm -f -- "$staging_file"
              return 1
          end

          function __gitdll_replace_plugin_core_from_file --argument-names source_file destination_file
              set --local staging_file "$destination_file.gitdll-new"
              command rm -f -- "$staging_file"
              if command cp -- "$source_file" "$staging_file"; and test -s "$staging_file"
                  command mv -- "$staging_file" "$destination_file"
                  return $status
              end
              command rm -f -- "$staging_file"
              return 1
          end


          set repositories

          if test (count $repository_inputs) -eq 1; and \
                  test -f "$repository_inputs[1]"
              while read -l line
                  # Lists may contain headings, blank lines, or Markdown links.
                  # Preserve each GitHub repository URL found in the text.
                  set repositories $repositories (string match -r -a '(?i)(?:https?://)?(?:www\.)?github\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\.git)?' "$line")
              end < "$repository_inputs[1]"
          else
              set repositories $repository_inputs
          end

          if test (count $repositories) -eq 0
              echo "Error: No repository links were found."
              return 1
          end

          command mkdir -p -- "$destination"

          for repository_url in $repositories
              set repository_path (
                  string replace -r '^https?://github\.com/' ''' -- "$repository_url" |
                  string replace -r '\.git/?$' ''' |
                  string replace -r '/$' '''
              )

              set repository_parts (string split / "$repository_path")

              if test (count $repository_parts) -lt 2
                  echo
                  echo "Skipping invalid GitHub repository URL:"
                  echo "  $repository_url"
                  continue
              end

              set repository_owner "$repository_parts[1]"
              set repository_name "$repository_parts[2]"

              if test -z "$repository_owner"; or test -z "$repository_name"
                  echo
                  echo "Skipping invalid GitHub repository URL:"
                  echo "  $repository_url"
                  continue
              end

              set canonical_repository_url \
                  "https://github.com/$repository_owner/$repository_name"

              # Skip completed destinations before making any network requests.
              set existing_repository_file (
                  command find "$destination" \
                      -mindepth 2 \
                      -maxdepth 2 \
                      -type f \
                      -name repository-url.txt \
                      -exec grep -lF "$canonical_repository_url" {} \; \
                      2>/dev/null |
                  command head -n 1
              )

              if test -n "$existing_repository_file"
                  set existing_plugin_directory (
                      dirname "$existing_repository_file"
                  )
                  set existing_plugin_readme 0

                  if command find "$existing_plugin_directory" \
                          -maxdepth 1 \
                          -type f \
                          \( -iname "README" -o -iname "README.md" -o -iname "README.markdown" -o -iname "README.txt" \) \
                          -size +0c \
                          -print \
                          -quit | read --local existing_readme
                      set existing_plugin_readme 1
                  end

                  if test -r "$existing_plugin_directory/manifest.json"; and \
                          test -s "$existing_plugin_directory/manifest.json"; and \
                          command jq -e . \
                              "$existing_plugin_directory/manifest.json" \
                              >/dev/null 2>&1; and \
                          command jq --indent 2 . \
                              "$existing_plugin_directory/manifest.json" | \
                              command cmp -s - "$existing_plugin_directory/manifest.json"; and \
                          test -r "$existing_plugin_directory/main.js"; and \
                          test -s "$existing_plugin_directory/main.js"; and \
                          test "$existing_plugin_readme" -eq 1

                      echo
                      echo "Skipping:"
                      echo "  $existing_plugin_directory (already complete)"
                      continue
                  end
              end

              echo
              echo "Repository:"
              echo "  $canonical_repository_url"

              command mkdir -p -- "$TMPDIR"

              set temporary_directory (
                  command mktemp -d \
                      "$TMPDIR/gitdll-plugins.XXXXXXXXXX"
              )

              if test -z "$temporary_directory"
                  echo "Error: Could not create a temporary directory."
                  continue
              end

              set repository_extract \
                  "$temporary_directory/repository"

              command mkdir -p -- "$repository_extract"

              # Fetch repository file paths using the original working mechanism.
              set repository_paths (
                  command gh api \
                      "repos/$repository_owner/$repository_name/git/trees/HEAD?recursive=1" \
                      --jq '.tree[]? | select(.type == "blob") | .path' \
                      2>/dev/null
              )

              # Filter only what may be considered for download.
              set filtered_repository_paths

              for repository_path in $repository_paths
                  if string match -rq \
                          '(^|/)\.[^/]+' \
                          "$repository_path"; or \
                          string match -rq \
                          '(^|/)node_modules/' \
                          "$repository_path"; or \
                          __obsidian_download_path_blocked \
                              "$repository_path"

                      continue
                  end

                  set --append filtered_repository_paths \
                      "$repository_path"
              end

              set repository_paths \
                  $filtered_repository_paths

              # Prefer standard files from the newest release before repository fallback.
              set release_theme_css 0
              set release_obsidian_css 0
              set release_json (
                  command gh api \
                      "repos/$repository_owner/$repository_name/releases/latest" \
                      2>/dev/null
              )

              if test $status -eq 0; and test -n "$release_json"
                  set release_assets (
                      printf "%s" "$release_json" |
                      command jq -r \
                          '.assets[]?
                          | [.name, .browser_download_url]
                          | @tsv'
                  )

                  for release_asset in $release_assets
                      set release_asset_parts (
                          string split \t "$release_asset"
                      )

                      if test (count $release_asset_parts) -lt 2
                          continue
                      end

                      set release_asset_name "$release_asset_parts[1]"
                      set release_asset_url "$release_asset_parts[2]"

                      if __obsidian_download_path_blocked \
                              "$release_asset_name"

                          continue
                      end

                      switch "$release_asset_name"
                          case manifest.json main.js styles.css
                              command curl \
                                  --fail \
                                  --location \
                                  --silent \
                                  --show-error \
                                  --output "$repository_extract/$release_asset_name" \
                                  "$release_asset_url"
                      end
                  end
              end

              for expected_file in manifest.json main.js styles.css
                  if test -f "$repository_extract/$expected_file"
                      continue
                  end

                  set repository_file_path (
                      printf '%s\n' $repository_paths |
                      command awk -F/ \
                          -v expected_file="$expected_file" \
                          '$NF == expected_file { print; exit }'
                  )

                  if test -z "$repository_file_path"
                      continue
                  end

                  set repository_file_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$repository_file_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -z "$repository_file_url"; or \
                          not command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$repository_extract/$expected_file" \
                          "$repository_file_url"

                      echo "Notice: Could not fetch repository file: $expected_file"
                  end
              end

              # Preserve one README when the repository provides one.
              for readme_name in README README.md README.markdown README.org README.txt
                  set readme_path (
                      printf '%s\n' $repository_paths |
                      command awk -F/ \
                          -v readme_name="$readme_name" \
                          '$NF == readme_name { print; exit }'
                  )

                  if test -z "$readme_path"
                      continue
                  end

                  set readme_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$readme_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -n "$readme_url"
                      command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$repository_extract/$readme_name" \
                          "$readme_url"
                      or echo "Notice: Could not fetch repository README."
                  end

                  break
              end

              set manifest (
                  command find "$repository_extract" \
                      -type f \
                      -name "manifest.json" \
                      -not -path "*/node_modules/*" \
                      -print \
                      -quit
              )

              if test -z "$manifest"
                  # A compiled plugin can still be installed when its repository
                  # omitted manifest.json. Prefer package metadata, then use the
                  # repository folder as the stable Obsidian plugin identity.
                  set generated_plugin_id (
                      __obsidian_repository_fallback_name "$repository_name"
                  )
                  set generated_plugin_name "$generated_plugin_id"
                  set generated_plugin_version "0.0.0"
                  set generated_plugin_author "$repository_owner"
                  set package_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/package.json" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -n "$package_url"; and command curl \
                          --fail --location --silent --show-error \
                          --output "$repository_extract/package.json" \
                          "$package_url"
                      set package_id (
                          command jq -r 'if (.id | type) == "string" then .id elif (.name | type) == "string" then .name else empty end' \
                              "$repository_extract/package.json" | string trim
                      )
                      set package_name (
                          command jq -r 'if (.name | type) == "string" then .name else empty end' \
                              "$repository_extract/package.json" | string trim
                      )
                      set package_version (
                          command jq -r 'if (.version | type) == "string" then .version else empty end' \
                              "$repository_extract/package.json" | string trim
                      )
                      set package_author (
                          command jq -r 'if (.author | type) == "string" then .author else empty end' \
                              "$repository_extract/package.json" | string trim
                      )

                      if test -n "$package_id"; and not string match -rq '[/\\x00]' "$package_id"
                          set generated_plugin_id "$package_id"
                      end
                      if test -n "$package_name"; and not string match -rq '[/\\x00]' "$package_name"
                          set generated_plugin_name "$package_name"
                      end
                      if test -n "$package_version"
                          set generated_plugin_version "$package_version"
                      end
                      if test -n "$package_author"
                          set generated_plugin_author "$package_author"
                      end
                  end

                  set manifest "$repository_extract/manifest.json"
                  if not command jq -n \
                          --arg id "$generated_plugin_id" \
                          --arg name "$generated_plugin_name" \
                          --arg version "$generated_plugin_version" \
                          --arg author "$generated_plugin_author" \
                          '{ id: $id, name: $name, version: $version, minAppVersion: "0.0.0", author: $author, generatedManifest: true }' \
                          >"$manifest"
                      echo "Error: Could not generate plugin manifest.json."
                      command rm -rf -- "$temporary_directory"
                      continue
                  end
              end

              if not command jq -e . "$manifest" >/dev/null
                  echo "Error: manifest.json is invalid."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set manifest_directory (dirname "$manifest")

              set plugin_id (
                  command jq -r \
                      'if type == "object" then
                        if (.id | type) == "string" then .id else empty end
                      else
                        empty
                      end' \
                      "$manifest" |
                  string trim
              )

              set plugin_name (
                  command jq -r \
                      'if type == "object" then
                        if (.name | type) == "string" then .name else empty end
                      else
                        empty
                      end' \
                      "$manifest" |
                  string trim
              )

              # Plugins prefer manifest.id, then manifest.name, then the cleaned
              # GitHub repository name when the manifest supplies neither.
              set plugin_folder_name "$plugin_id"

              if test -z "$plugin_folder_name"
                  set plugin_folder_name "$plugin_name"
              end

              if test -z "$plugin_folder_name"
                  set plugin_folder_name (
                      __obsidian_repository_fallback_name \
                          "$repository_name"
                  )
              end

              if test -z "$plugin_folder_name"
                  echo "Error: Repository name cannot produce a plugin folder name."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if string match -rq '[/\x00]' "$plugin_folder_name"
                  echo "Error: Plugin folder name contains unsafe characters."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if test "$plugin_folder_name" = "."
                  echo "Error: Plugin folder name is unsafe."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if test "$plugin_folder_name" = ".."
                  echo "Error: Plugin folder name is unsafe."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set plugin_directory "$destination/$plugin_folder_name"
              set plugin_directory_exists 0
              set refresh_plugin_manifest 0

              if test -d "$plugin_directory"
                  set plugin_readme_ok 0

                  if command find "$plugin_directory" \
                          -maxdepth 1 \
                          -type f \
                          \( -iname "README" -o -iname "README.md" -o -iname "README.markdown" -o -iname "README.txt" \) \
                          -size +0c \
                          -print \
                          -quit | read --local plugin_readme
                      set plugin_readme_ok 1
                  end

                  if __gitdll_plugin_core_is_healthy "$plugin_directory"; and \
                          command jq -e \
                              --arg url "$canonical_repository_url" \
                              '.pluginUrl == $url' \
                              "$plugin_directory/manifest.json" \
                              >/dev/null 2>&1; and \
                          test "$plugin_readme_ok" -eq 1

                      echo
                      echo "Skipping:"
                      echo "  $plugin_folder_name (already complete)"
                      command rm -rf -- "$temporary_directory"
                      continue
                  end

                  echo
                  echo "Resuming incomplete plugin:"
                  echo "  $plugin_folder_name"
                  set plugin_directory_exists 1
                  set refresh_plugin_manifest 1
              end

              set plugin_stage "$temporary_directory/plugin"

              if test "$plugin_directory_exists" -eq 1
                  set plugin_stage "$plugin_directory"
              else
                  command mkdir -p -- "$plugin_stage"
              end

              if not test -r "$plugin_stage/manifest.json"; or \
                      not test -s "$plugin_stage/manifest.json"; or \
                      test "$refresh_plugin_manifest" -eq 1; or \
                      not command jq -e . \
                          "$plugin_stage/manifest.json" \
                          >/dev/null 2>&1
                  __gitdll_replace_plugin_core_from_file \
                      "$manifest" \
                      "$plugin_stage/manifest.json"
              end

              set saved_files
              set deferred_plugin_archives

              if test -f "$plugin_stage/manifest.json"
                  set saved_files manifest.json
              end

              set release_json (
                  command gh api \
                      "repos/$repository_owner/$repository_name/releases/latest" \
                      2>/dev/null
              )

              if test $status -eq 0; and test -n "$release_json"
                  set release_assets (
                      printf "%s" "$release_json" |
                      command jq -r \
                          '.assets[]?
                          | [.name, .browser_download_url]
                          | @tsv'
                  )

                  for release_asset in $release_assets
                      set release_asset_parts (
                          string split \t "$release_asset"
                      )

                      if test (count $release_asset_parts) -lt 2
                          continue
                      end

                      set release_asset_name "$release_asset_parts[1]"
                      set release_asset_url "$release_asset_parts[2]"

                      if __obsidian_download_path_blocked \
                              "$release_asset_name"

                          continue
                      end

                      switch "$release_asset_name"
                          case main.js styles.css manifest.json
                              if test -r "$plugin_stage/$release_asset_name"; and \
                                      test -s "$plugin_stage/$release_asset_name"; and \
                                      test "$refresh_plugin_manifest" -eq 0
                                  continue
                              end

                              if __gitdll_replace_plugin_core_from_url \
                                      "$plugin_stage/$release_asset_name" \
                                      "$release_asset_url"

                                  if not contains \
                                          "$release_asset_name" \
                                          $saved_files

                                      set saved_files \
                                          $saved_files \
                                          "$release_asset_name"
                                  end
                              else
                                  echo \
                                      "Notice: Could not download release asset: $release_asset_name"
                              end

                          case '*'
                              if __obsidian_is_named_release_archive \
                                      "$release_asset_name" \
                                      "$plugin_folder_name" \
                                      "$repository_name"
                                  if string match -ri '\\.zip$' "$release_asset_name"
                                      set --append deferred_plugin_archives \
                                          "$release_asset"
                                  end
                                  continue
                              end

                              # Every actual GitHub release asset stays at the
                              # plugin root. GitHub's generated source archives are
                              # not included in the release assets API.
                              if test -e "$plugin_stage/$release_asset_name"
                                  continue
                              end

                              if command curl \
                                      --fail \
                                      --location \
                                      --silent \
                                      --show-error \
                                      --output "$plugin_stage/$release_asset_name" \
                                      "$release_asset_url"

                                  set saved_files \
                                      $saved_files \
                                      "$release_asset_name"
                              else
                                  echo \
                                      "Notice: Could not download release asset: $release_asset_name"
                              end
                      end
                  end
              else
                  echo "Notice: No GitHub release was found."
              end

              for expected_file in main.js styles.css
                  if test -r "$plugin_stage/$expected_file"; and \
                          test -s "$plugin_stage/$expected_file"; and \
                          test "$refresh_plugin_manifest" -eq 0
                      continue
                  end

                  set repository_file \
                      "$manifest_directory/$expected_file"

                  if not test -f "$repository_file"
                      set repository_file (
                          command find "$repository_extract" \
                              -type f \
                              -name "$expected_file" \
                              -not -path "*/node_modules/*" \
                              -print \
                              -quit
                      )
                  end

                  if test -n "$repository_file"
                      __gitdll_replace_plugin_core_from_file \
                          "$repository_file" \
                          "$plugin_stage/$expected_file"

                      if not contains "$expected_file" $saved_files
                          set saved_files \
                              $saved_files \
                              "$expected_file"
                      end
                  end
              end

              # A distribution archive named after the plugin is only needed
              # when neither release nor repository supplied a usable core.
              # styles.css is deliberately not part of this decision: it stays
              # an independent optional release/repository asset.
              if not __gitdll_plugin_payload_is_healthy "$plugin_stage"
                  for deferred_plugin_archive in $deferred_plugin_archives
                      set deferred_plugin_archive_parts \
                          (string split \t "$deferred_plugin_archive")

                      if test (count $deferred_plugin_archive_parts) -lt 2
                          continue
                      end

                      set deferred_plugin_archive_name \
                          "$deferred_plugin_archive_parts[1]"
                      set deferred_plugin_archive_url \
                          "$deferred_plugin_archive_parts[2]"

                      if test -e "$plugin_stage/$deferred_plugin_archive_name"
                          continue
                      end

                      if command curl \
                              --fail \
                              --location \
                              --silent \
                              --show-error \
                              --output "$plugin_stage/$deferred_plugin_archive_name" \
                              "$deferred_plugin_archive_url"

                          set saved_files \
                              $saved_files \
                              "$deferred_plugin_archive_name"
                      else
                          echo \
                              "Notice: Could not download release asset: $deferred_plugin_archive_name"
                      end
                  end
              end

              # Collect repository auxiliary files first so root/repo placement can
              # be decided before anything is written.
              set repository_auxiliary_paths

              for auxiliary_path in $repository_paths
                  set auxiliary_path_supported 0
                  set auxiliary_name \
                      (basename "$auxiliary_path")

                  # Preserve every file inside documentation folders because
                  # supporting scripts and other files may be required by docs.
                  if string match -rq \
                          '(?i)(^|/)(doc|docs|documentation|wiki)/' \
                          "$auxiliary_path"

                      set auxiliary_path_supported 1

                  # Preserve Markdown and OrgMode files regardless of folder name.
                  else if string match -rq \
                          '(?i)\.(md|markdown|org)$' \
                          "$auxiliary_path"; and \
                          not string match -rq \
                          '(?i)^README(?:\.(md|markdown|org|txt))?$' \
                          "$auxiliary_name"

                      set auxiliary_path_supported 1

                  else if string match -rq \
                          '(?i)(^|/)[^/]*(assets|gallery|galleries|img|imgs|images|image|screenshots|screenshot|previews|preview)[^/]*/.*\.(png|jpe?g|gif|webp)$' \
                          "$auxiliary_path"

                      set auxiliary_path_supported 1

                  else if string match -rq \
                          '(?i)(screen|screencap|screenshot|image|preview).*?\.(png|jpe?g|gif|webp)$' \
                          "$auxiliary_name"

                      set auxiliary_path_supported 1
                  end

                  if test "$auxiliary_path_supported" -eq 1
                      set --append repository_auxiliary_paths \
                          "$auxiliary_path"
                  end
              end

              set use_repository_subfolder 0

              # Multiple repository auxiliary files use repo/.
              if test (count $repository_auxiliary_paths) -gt 1
                  set use_repository_subfolder 1
              end

              # A remote subfolder must be preserved exactly beneath repo/.
              for auxiliary_path in $repository_auxiliary_paths
                  if string match -q '*/*' "$auxiliary_path"
                      set use_repository_subfolder 1
                      break
                  end
              end

              # Existing repo/ remains active when it already represents a grouped
              # auxiliary layout.
              if test -d "$plugin_stage/repo"
                  if command find "$plugin_stage/repo" \
                          -mindepth 1 \
                          -type d \
                          -print \
                          -quit | read --local existing_repo_directory

                      set use_repository_subfolder 1
                  else
                      set existing_repo_files (
                          command find "$plugin_stage/repo" \
                              -mindepth 1 \
                              -type f \
                              -print
                      )

                      if test (count $existing_repo_files) -gt 1
                          set use_repository_subfolder 1
                      else if test (count $existing_repo_files) -eq 1; and \
                              test "$use_repository_subfolder" -eq 0

                          set existing_repo_file \
                              "$existing_repo_files[1]"

                          set existing_repo_destination \
                              "$plugin_stage/"(basename "$existing_repo_file")

                          if not test -e "$existing_repo_destination"
                              command mv \
                                  "$existing_repo_file" \
                                  "$existing_repo_destination"
                          end

                          command rm -rf \
                              "$plugin_stage/repo"
                      end
                  end
              end

              for auxiliary_path in $repository_auxiliary_paths
                  set auxiliary_destination \
                      "$plugin_stage/"(basename "$auxiliary_path")

                  if test "$use_repository_subfolder" -eq 1
                      set auxiliary_destination \
                          "$plugin_stage/repo/$auxiliary_path"
                  end

                  if test -s "$auxiliary_destination"
                      continue
                  end

                  command mkdir -p \
                      (dirname "$auxiliary_destination")

                  # GitHub CLI's raw response transform can fail for binary
                  # images and GIFs. Resolve the raw URL as metadata, then
                  # use curl to download a staged file before replacing it.
                  set auxiliary_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$auxiliary_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  set auxiliary_staging "$auxiliary_destination.gitdll-new"
                  command rm -f -- "$auxiliary_staging"

                  if test -n "$auxiliary_url"; and \
                      command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$auxiliary_staging" \
                          "$auxiliary_url"; and \
                      test -s "$auxiliary_staging"; and \
                      command mv -- "$auxiliary_staging" "$auxiliary_destination"

                      set saved_files \
                          $saved_files \
                          (string replace "$plugin_stage/" "" -- "$auxiliary_destination")
                  else
                      command rm -f \
                          "$auxiliary_staging"

                      echo \
                          "Notice: Could not download plugin repository file: $auxiliary_path"
                  end
              end

              if not test -r "$plugin_stage/main.js"; or \
                      not test -s "$plugin_stage/main.js"
                  echo "Error: main.js was not found in the release or repository."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set readme (
                  command find "$manifest_directory" \
                      -type f \
                      \( \
                          -iname "README" \
                          -o -iname "README.md" \
                          -o -iname "README.markdown" \
                          -o -iname "README.txt" \
                      \) \
                      -not -path "*/node_modules/*" \
                      -print \
                      -quit
              )

              if test -z "$readme"
                  set readme (
                      command find "$repository_extract" \
                          -type f \
                          \( \
                              -iname "README" \
                              -o -iname "README.md" \
                              -o -iname "README.markdown" \
                              -o -iname "README.txt" \
                          \) \
                          -not -path "*/node_modules/*" \
                          -print \
                          -quit
                  )
              end

              if test -n "$readme"; and test -f "$readme"
                  set readme_extension (
                      string match -r '\.[^.]+$' \
                          (basename "$readme")
                  )

                  set readme_output README

                  if test -n "$readme_extension"
                      set readme_output \
                          "README$readme_extension"
                  end

                  set readme_destination_root \
                      "$plugin_stage"

                  # Any auxiliary repository content activates repo/.
                  if test -d "$plugin_stage/repo"; and \
                          command find "$plugin_stage/repo" \
                          -mindepth 1 \
                          -print \
                          -quit | read --local existing_repo_content

                      set readme_destination_root \
                          "$plugin_stage/repo"
                  end

                  # Move an existing root README into repo/ when auxiliary mode
                  # becomes active.
                  if test "$readme_destination_root" = "$plugin_stage/repo"; and \
                          test -e "$plugin_stage/$readme_output"; and \
                          not test -e "$readme_destination_root/$readme_output"

                      command mkdir -p \
                          "$readme_destination_root"

                      command mv \
                          "$plugin_stage/$readme_output" \
                          "$readme_destination_root/$readme_output"
                  end

                  if not test -e "$readme_destination_root/$readme_output"; or \
                          test "$refresh_plugin_manifest" -eq 1

                      command mkdir -p \
                          "$readme_destination_root"

                      command cp -f \
                          "$readme" \
                          "$readme_destination_root/$readme_output"
                  end

                  set saved_files \
                      $saved_files \
                      (string replace "$plugin_stage/" "" -- "$readme_destination_root/$readme_output")
              else
                  echo "Notice: No README file was found."
              end

              if not command jq \
                      --arg url "$canonical_repository_url" \
                      '.pluginUrl = $url' \
                      "$plugin_stage/manifest.json" \
                      >"$plugin_stage/manifest.json.gitdll-new"; or \
                      not command mv \
                      -- \
                      "$plugin_stage/manifest.json.gitdll-new" \
                      "$plugin_stage/manifest.json"
                  command rm -f -- "$plugin_stage/manifest.json.gitdll-new"
                  echo "Error: Could not save pluginUrl in manifest.json."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              __obsidian_normalize_download_layout "$plugin_stage"

              if test "$plugin_directory_exists" -eq 1
                  echo "Updated:"
                  echo "  $plugin_directory"
              else if not command mv \
                      -- \
                      "$plugin_stage" \
                      "$plugin_directory"

                  echo "Error: Could not save the plugin directory."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              echo "Saved:"
              echo "  $plugin_directory"

              echo "Files:"

              for saved_file in $saved_files
                  echo "  $saved_file"
              end

              command rm -rf -- "$temporary_directory"
          end
        '';
      };
      # -----------------------------------------------------------------

      # -----------------------------------------------------------------
      # ---- gitdll-plugins and gitdll-themes -> Obsidian download shortcuts ---- #
      # -----------------------------------------------------------------
      gitdll-plugins = {
        description = "Download Obsidian plugins with gitdll's plugin mode";

        body = ''
          gitdll --plugins $argv
        '';
      };

      gitdll-themes = {
        description = "Download Obsidian themes with gitdll's theme mode";

        body = ''
          gitdll --themes $argv
        '';
      };
      # -----------------------------------------------------------------

      # -----------------------------------------------------------------
      # ---- __gitdll_themes -> Internal Obsidian theme downloader ---- #
      # -----------------------------------------------------------------
      __gitdll_themes = {
        description = "Download Obsidian themes and repository metadata";

        body = ''
          # Parse repository URLs and an optional destination path.
          set --local destination "$HOME/Downloads/gitdll-themes"
          set --local repository_inputs
          set --local expecting_destination 0

          if test (count $argv) -eq 0
              echo "Usage:"
              echo '  gitdll-themes <links.txt>'
              echo '  gitdll-themes "https://github.com/owner/repository" [...]'
              echo '  gitdll-themes <links.txt-or-repository-url> [...] --to "destination path"'
              return 1
          end

          for argument in $argv
              switch "$argument"
                  case --to
                      if test "$expecting_destination" -eq 1
                          echo "Error: --to requires a destination path."
                          return 1
                      end

                      set expecting_destination 1

                  case '--*'
                      echo "Error: Unknown option:"
                      echo "  $argument"
                      return 1

                  case '*'
                      if test "$expecting_destination" -eq 1
                          set destination "$argument"
                          set expecting_destination 0
                      else
                          set repository_inputs $repository_inputs "$argument"
                      end
              end
          end

          if test "$expecting_destination" -eq 1
              echo "Error: --to requires a destination path."
              return 1
          end

          if not command -q jq
              echo "Error: jq is not installed."
              return 1
          end

          if not command -q curl
              echo "Error: curl is not installed."
              return 1
          end

          if not command -q gh
              echo "Error: gh is not installed."
              return 1
          end

          if not command -q node
              echo "Error: node is not installed."
              return 1
          end

          function __gitdll_theme_stylesheet_is_healthy --argument-names stylesheet_file
              if not test -f "$stylesheet_file"; or not test -s "$stylesheet_file"
                  return 1
              end
              command node -e '
                const source = require("node:fs").readFileSync(process.argv[1], "utf8");
                let depth = 0, quote = "", escaped = false, comment = false;
                for (let index = 0; index < source.length; index += 1) {
                  const character = source[index], next = source[index + 1] || "";
                  if (comment) { if (character === "*" && next === "/") { comment = false; index += 1; } continue; }
                  if (quote) { if (escaped) escaped = false; else if (character === "\\\\") escaped = true; else if (character === quote) quote = ""; continue; }
                  if (character === "/" && next === "*") { comment = true; index += 1; }
                  else if (character === "\"") quote = character;
                  else if (character === "{") depth += 1;
                  else if (character === "}") { depth -= 1; if (depth < 0) process.exit(1); }
                }
                if (comment || quote || depth !== 0) process.exit(1);
              ' "$stylesheet_file" >/dev/null 2>&1
          end

          function __gitdll_replace_theme_core_from_file --argument-names source_file destination_file
              set --local staging_file "$destination_file.gitdll-new"
              command rm -f -- "$staging_file"
              if command cp -- "$source_file" "$staging_file"; and test -s "$staging_file"
                  command mv -- "$staging_file" "$destination_file"
                  return $status
              end
              command rm -f -- "$staging_file"
              return 1
          end

          set repositories

          if test (count $repository_inputs) -eq 1; and \
                  test -f "$repository_inputs[1]"
              while read -l line
                  # Lists may contain headings, blank lines, or Markdown links.
                  # Preserve each GitHub repository URL found in the text.
                  set repositories $repositories (string match -r -a '(?i)(?:https?://)?(?:www\.)?github\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\.git)?' "$line")
              end < "$repository_inputs[1]"
          else
              set repositories $repository_inputs
          end

          if test (count $repositories) -eq 0
              echo "Error: No repository links were found."
              return 1
          end

          command mkdir -p -- "$destination"

          for repository_url in $repositories
              set repository_path (
                  string replace -r '^https?://github\.com/' ''' -- "$repository_url" |
                  string replace -r '\.git/?$' ''' |
                  string replace -r '/$' '''
              )

              set repository_parts (string split / "$repository_path")

              if test (count $repository_parts) -lt 2
                  echo
                  echo "Skipping invalid GitHub repository URL:"
                  echo "  $repository_url"
                  continue
              end

              set repository_owner "$repository_parts[1]"
              set repository_name "$repository_parts[2]"

              if test -z "$repository_owner"; or test -z "$repository_name"
                  echo
                  echo "Skipping invalid GitHub repository URL:"
                  echo "  $repository_url"
                  continue
              end

              set canonical_repository_url \
                  "https://github.com/$repository_owner/$repository_name"

              # Keep the repository name as the final, filesystem-safe fallback.
              set fallback_folder_name "$repository_name"

              # Skip completed destinations before making any network requests.
              set existing_repository_file (
                  command find "$destination" \
                      -mindepth 2 \
                      -maxdepth 2 \
                      -type f \
                      -name repository-url.txt \
                      -exec grep -lF "$canonical_repository_url" {} \; \
                      2>/dev/null |
                  command head -n 1
              )

              if test -n "$existing_repository_file"
                  set existing_theme_directory (
                      dirname "$existing_repository_file"
                  )

                  set existing_theme_manifest_ok 1
                  set existing_theme_readme_ok 0

                  if command find "$existing_theme_directory" \
                          -maxdepth 1 \
                          -type f \
                          \( -iname "README" -o -iname "README.md" -o -iname "README.markdown" -o -iname "README.txt" \) \
                          -size +0c \
                          -print \
                          -quit | read --local existing_theme_readme
                      set existing_theme_readme_ok 1
                  end

                  if test -e "$existing_theme_directory/manifest.json"; and \
                          not test -r "$existing_theme_directory/manifest.json"; or \
                          test -e "$existing_theme_directory/manifest.json"; and \
                          not test -s "$existing_theme_directory/manifest.json"; or \
                          test -e "$existing_theme_directory/manifest.json"; and \
                          not command jq -e . \
                              "$existing_theme_directory/manifest.json" \
                              >/dev/null 2>&1
                      set existing_theme_manifest_ok 0
                  end

              end

              echo
              echo "Repository:"
              echo "  $canonical_repository_url"

              command mkdir -p -- "$TMPDIR"

              set temporary_directory (
                  command mktemp -d \
                      "$TMPDIR/gitdll-themes.XXXXXXXXXX"
              )

              if test -z "$temporary_directory"
                  echo "Error: Could not create a temporary directory."
                  continue
              end

              set extracted "$temporary_directory/repository"

              command mkdir -p "$extracted"

              # Fetch repository file paths using the original working mechanism.
              set repository_paths (
                  command gh api \
                      "repos/$repository_owner/$repository_name/git/trees/HEAD?recursive=1" \
                      --jq '.tree[]? | select(.type == "blob") | .path' \
                      2>/dev/null
              )

              # Filter only what may be considered for download.
              set filtered_repository_paths

              for repository_path in $repository_paths
                  if string match -rq \
                          '(^|/)\.[^/]+' \
                          "$repository_path"; or \
                          string match -rq \
                          '(^|/)node_modules/' \
                          "$repository_path"; or \
                          __obsidian_download_path_blocked \
                              "$repository_path"

                      continue
                  end

                  set --append filtered_repository_paths \
                      "$repository_path"
              end

              set repository_paths \
                  $filtered_repository_paths

              # Prefer standard files from the newest release before repository fallback.
              set release_theme_css 0
              set release_obsidian_css 0

              set release_json (
                  command gh api \
                      "repos/$repository_owner/$repository_name/releases/latest" \
                      2>/dev/null
              )

              if test $status -eq 0; and test -n "$release_json"
                  set release_assets (
                      printf "%s" "$release_json" |
                      command jq -r \
                          '.assets[]?
                          | [.name, .browser_download_url]
                          | @tsv'
                  )

                  for release_asset in $release_assets
                      set release_asset_parts (
                          string split \t "$release_asset"
                      )

                      if test (count $release_asset_parts) -lt 2
                          continue
                      end

                      set release_asset_name "$release_asset_parts[1]"
                      set release_asset_url "$release_asset_parts[2]"

                      if __obsidian_download_path_blocked \
                              "$release_asset_name"

                          continue
                      end

                      switch "$release_asset_name"
                          case manifest.json main.js
                              command curl \
                                  --fail \
                                  --location \
                                  --silent \
                                  --show-error \
                                  --output "$extracted/$release_asset_name" \
                                  "$release_asset_url"
                          case theme.css
                              if command curl \
                                      --fail \
                                      --location \
                                      --silent \
                                      --show-error \
                                      --output "$extracted/theme.css" \
                                      "$release_asset_url"
                                  set release_theme_css 1
                              end
                          case obsidian.css
                              if command curl \
                                      --fail \
                                      --location \
                                      --silent \
                                      --show-error \
                                      --output "$extracted/obsidian.css" \
                                      "$release_asset_url"
                                  set release_obsidian_css 1
                              end
                      end
                  end
              end

              set repository_primary_stylesheets 1
              if test "$release_theme_css" -eq 1; or test "$release_obsidian_css" -eq 1
                  set repository_primary_stylesheets 0
              end

              for expected_file in manifest.json theme.css obsidian.css
                  if test "$repository_primary_stylesheets" -eq 0; and \
                          test "$expected_file" != manifest.json
                      continue
                  end
                  if test -f "$extracted/$expected_file"
                      continue
                  end

                  set repository_file_path (
                      printf '%s\n' $repository_paths |
                      command awk -F/ \
                          -v expected_file="$expected_file" \
                          '$NF == expected_file { print; exit }'
                  )

                  if test -z "$repository_file_path"
                      continue
                  end

                  set repository_file_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$repository_file_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -z "$repository_file_url"; or \
                          not command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$extracted/$expected_file" \
                          "$repository_file_url"

                      echo "Notice: Could not fetch repository file: $expected_file"
                  end
              end

              # Preserve one README when the repository provides one.
              for readme_name in README README.md README.markdown README.org README.txt
                  set readme_path (
                      printf '%s\n' $repository_paths |
                      command awk -F/ \
                          -v readme_name="$readme_name" \
                          '$NF == readme_name { print; exit }'
                  )

                  if test -z "$readme_path"
                      continue
                  end

                  set readme_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$readme_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -n "$readme_url"
                      command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$extracted/$readme_name" \
                          "$readme_url"
                      or echo "Notice: Could not fetch repository README."
                  end

                  break
              end

              # Prefer matching assets from the newest GitHub release.
              set release_theme_archive_name "$fallback_folder_name"

              if test -s "$extracted/manifest.json"; and \
                      command jq -e 'type == "object"' \
                          "$extracted/manifest.json" \
                          >/dev/null 2>&1
                  set manifest_theme_name (
                      command jq -r \
                          'if (.name | type) == "string" and (.name | length) > 0 then .name
                           elif (.id | type) == "string" and (.id | length) > 0 then .id
                           else empty
                           end' \
                          "$extracted/manifest.json" |
                      string trim
                  )

                  if test -n "$manifest_theme_name"
                      set release_theme_archive_name "$manifest_theme_name"
                  end
              end

              set deferred_theme_archives

              set release_json (
                  command gh api \
                      "repos/$repository_owner/$repository_name/releases/latest" \
                      2>/dev/null
              )

              if test $status -eq 0; and test -n "$release_json"
                  set release_assets (
                      printf "%s" "$release_json" |
                      command jq -r \
                          '.assets[]?
                          | [.name, .browser_download_url]
                          | @tsv'
                  )

                  for release_asset in $release_assets
                      set release_asset_parts (
                          string split \t "$release_asset"
                      )

                      if test (count $release_asset_parts) -lt 2
                          continue
                      end

                      set release_asset_name "$release_asset_parts[1]"
                      set release_asset_url "$release_asset_parts[2]"

                      if __obsidian_download_name_blocked \
                              "$release_asset_name"

                          continue
                      end

                      switch "$release_asset_name"
                          case manifest.json theme.css obsidian.css main.js
                              if not command curl \
                                      --fail \
                                      --location \
                                      --silent \
                                      --show-error \
                                      --output "$extracted/$release_asset_name" \
                                      "$release_asset_url"

                                  echo \
                                      "Notice: Could not download release asset: $release_asset_name"
                              end

                          case '*'
                              if __obsidian_is_named_release_archive \
                                      "$release_asset_name" \
                                      "$release_theme_archive_name" \
                                      "$repository_name"
                                  if string match -ri '\\.zip$' "$release_asset_name"
                                      set --append deferred_theme_archives \
                                          "$release_asset"
                                  end
                                  continue
                              end

                              # Every other actual GitHub release asset is retained.
                              # GitHub's generated source archives are not members of
                              # the release assets API.
                              command mkdir -p \
                                  "$extracted/release-assets"

                              if not command curl \
                                      --fail \
                                      --location \
                                      --silent \
                                      --show-error \
                                      --output "$extracted/release-assets/$release_asset_name" \
                                      "$release_asset_url"

                                  echo \
                                      "Notice: Could not download release asset: $release_asset_name"
                              end
                      end
                  end
              end

              # A named ZIP is used only after neither the release nor the
              # repository has supplied a usable theme core payload.
              set release_theme_payload_available 0
              if test -s "$extracted/manifest.json"
                  if test -s "$extracted/theme.css"; or \
                          test -s "$extracted/obsidian.css"
                      set release_theme_payload_available 1
                  end
              end

              if test "$release_theme_payload_available" -eq 0
                  for deferred_theme_archive in $deferred_theme_archives
                      set deferred_theme_archive_parts \
                          (string split \t "$deferred_theme_archive")

                      if test (count $deferred_theme_archive_parts) -lt 2
                          continue
                      end

                      set deferred_theme_archive_name \
                          "$deferred_theme_archive_parts[1]"
                      set deferred_theme_archive_url \
                          "$deferred_theme_archive_parts[2]"

                      command mkdir -p "$extracted/release-assets"

                      if not command curl \
                              --fail \
                              --location \
                              --silent \
                              --show-error \
                              --output "$extracted/release-assets/$deferred_theme_archive_name" \
                              "$deferred_theme_archive_url"

                          echo \
                              "Notice: Could not download release asset: $deferred_theme_archive_name"
                      end
                  end
              end

              set manifest (
                  command find "$extracted" \
                      -type f \
                      -name "manifest.json" \
                      -not -path "*/node_modules/*" \
                      -print \
                      -quit
              )

              if test -n "$manifest"; and \
                      not command jq -e . "$manifest" >/dev/null
                  echo "Error: manifest.json is invalid."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set manifest_directory "$extracted"
              set theme_name
              set theme_id

              if test -n "$manifest"
                  set manifest_directory (dirname "$manifest")

                  set theme_name (
                      command jq -r \
                          'if type == "object" then
                            if (.name | type) == "string" then .name else empty end
                          else
                            empty
                          end' \
                          "$manifest" |
                      string trim
                  )

                  set theme_id (
                      command jq -r \
                          'if type == "object" then
                            if (.id | type) == "string" then .id else empty end
                          else
                            empty
                          end' \
                          "$manifest" |
                      string trim
                  )
              end

              # Themes prefer manifest.name, then manifest.id, then the cleaned
              # GitHub repository name when the manifest supplies neither.
              set theme_folder_name "$theme_name"

              if test -z "$theme_folder_name"
                  set theme_folder_name "$theme_id"
              end

              if test -z "$theme_folder_name"
                  set theme_folder_name (
                      __obsidian_repository_fallback_name \
                          "$fallback_folder_name"
                  )
              end

              if test -z "$theme_folder_name"
                  echo "Error: Repository name cannot produce a theme folder name."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if string match -rq '[/\x00]' "$theme_folder_name"
                  echo "Error: Theme name contains unsafe folder-name characters."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if test "$theme_folder_name" = "."
                  echo "Error: Theme name contains an unsafe folder name."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if test "$theme_folder_name" = ".."
                  echo "Error: Theme name contains an unsafe folder name."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set source_theme_css \
                  "$manifest_directory/theme.css"

              if not test -f "$source_theme_css"
                  set source_theme_css (
                      command find "$extracted" \
                          -type f \
                          -name "theme.css" \
                          -not -path "*/node_modules/*" \
                          -print \
                          -quit
                  )
              end

              set source_obsidian_css \
                  "$manifest_directory/obsidian.css"

              if not test -f "$source_obsidian_css"
                  set source_obsidian_css (
                      command find "$extracted" \
                          -type f \
                          -name "obsidian.css" \
                          -not -path "*/node_modules/*" \
                          -print \
                          -quit
                  )
              end

              if not test -f "$source_theme_css"; and \
                      not test -f "$source_obsidian_css"

                  echo \
                      "Error: Neither theme.css nor obsidian.css was found."

                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set readme (
                  command find "$manifest_directory" \
                      -type f \
                      \( \
                          -iname "README" \
                          -o -iname "README.md" \
                          -o -iname "README.markdown" \
                          -o -iname "README.txt" \
                      \) \
                      -not -path "*/node_modules/*" \
                      -print \
                      -quit
              )

              if test -z "$readme"
                  set readme (
                      command find "$extracted" \
                          -type f \
                          \( \
                              -iname "README" \
                              -o -iname "README.md" \
                              -o -iname "README.markdown" \
                              -o -iname "README.txt" \
                          \) \
                          -not -path "*/node_modules/*" \
                          -print \
                          -quit
                  )
              end

              set theme_directory \
                  "$destination/$theme_folder_name"
              set theme_directory_exists 0
              set refresh_theme_core 0

              if test -d "$theme_directory"
                  set theme_manifest_ok 1
                  set theme_readme_ok 0

                  if command find "$theme_directory" \
                          -maxdepth 1 \
                          -type f \
                          \( -iname "README" -o -iname "README.md" -o -iname "README.markdown" -o -iname "README.txt" \) \
                          -size +0c \
                          -print \
                          -quit | read --local existing_theme_readme
                      set theme_readme_ok 1
                  end

                  if test -e "$theme_directory/manifest.json"; and \
                          not test -r "$theme_directory/manifest.json"; or \
                          test -e "$theme_directory/manifest.json"; and \
                          not test -s "$theme_directory/manifest.json"; or \
                          test -e "$theme_directory/manifest.json"; and \
                          not command jq -e . \
                              "$theme_directory/manifest.json" \
                              >/dev/null 2>&1
                      set theme_manifest_ok 0
                  end

                  if test "$theme_manifest_ok" -eq 0; or \
                      not __gitdll_theme_stylesheet_is_healthy "$theme_directory/theme.css"
                      set refresh_theme_core 1
                  end

                  # Existing themes are refreshed so newly supported repository
                  # screenshots and asset folders are added on later runs.
                  set theme_directory_exists 1
              end

              set theme_stage "$temporary_directory/theme"

              if test "$theme_directory_exists" -eq 1
                  set theme_stage "$theme_directory"
              else
                  command mkdir -p -- "$theme_stage"
              end

              set saved_files

              # A lone root screenshot and README stay at the theme root. Multiple
              # screenshots, or any supported screenshot folder, keep their
              # repository-relative layout under repo/.
              set repository_image_paths
              set use_repository_subfolder 0
              for repository_path in $repository_paths
                  set repository_image_name (basename "$repository_path")

                  set is_root_image 0
                  set has_image_keyword 0
                  set is_preview_folder_image 0
                  set is_repository_named_image 0

                  if not string match -q '*/*' "$repository_path"; and \
                          string match -rq \
                          '(?i)\.(png|jpe?g|gif|webp)$' \
                          "$repository_image_name"
                      set is_root_image 1
                  end

                  if string match -rq \
                          '(?i)(screen|screencap|screenshot|image|preview|previews).*?\.(png|jpe?g|gif|webp)$' \
                          "$repository_image_name"
                      set has_image_keyword 1
                  end

                  if string match -rq \
                          '(?i)(^|/)[^/]*(assets|gallery|galleries|img|imgs|images|image|screenshots|screenshot|previews|preview)[^/]*/.*\.(png|jpe?g|gif|webp)$' \
                          "$repository_path"
                      set is_preview_folder_image 1
                  end

                  # Preserve supported images whose filename contains the
                  # normalized repository/theme name.
                  if string match -rq \
                          '(?i)\.(png|jpe?g|gif|webp)$' \
                          "$repository_image_name"

                      set normalized_repository_name (
                          string lower -- "$repository_name" |
                          string replace -ra '[^0-9a-z]+' ""
                      )

                      set normalized_image_name (
                          string replace -r \
                              '\.[^.]+$' \
                              "" \
                              "$repository_image_name" |
                          string lower |
                          string replace -ra '[^0-9a-z]+' ""
                      )

                      if test -n "$normalized_repository_name"; and \
                              string match -q \
                              "*$normalized_repository_name*" \
                              "$normalized_image_name"

                          set is_repository_named_image 1
                      end
                  end

                  if test "$is_root_image" -eq 0; and \
                          test "$has_image_keyword" -eq 0; and \
                          test "$is_preview_folder_image" -eq 0; and \
                          test "$is_repository_named_image" -eq 0
                      continue
                  end

                  set --append repository_image_paths "$repository_path"

                  if string match -q '*/*' "$repository_path"
                      set use_repository_subfolder 1
                  end
              end
              # Documentation and snippets participate in the same auxiliary
              # layout decision as repository images.
              set repository_auxiliary_paths \
                  $repository_image_paths

              for repository_path in $repository_paths
                  set repository_file_name \
                      (basename "$repository_path")

                  if string match -rq \
                          '(?i)(^|/)(doc|docs|documentation|wiki)/' \
                          "$repository_path"

                      if not contains \
                              "$repository_path" \
                              $repository_auxiliary_paths

                          set --append repository_auxiliary_paths \
                              "$repository_path"
                      end

                  else if string match -rq \
                          '(?i)\.(md|markdown|org)$' \
                          "$repository_path"; and \
                          not string match -rq \
                          '(?i)^README(?:\.(md|markdown|org|txt))?$' \
                          "$repository_file_name"

                      if not contains \
                              "$repository_path" \
                              $repository_auxiliary_paths

                          set --append repository_auxiliary_paths \
                              "$repository_path"
                      end
                  end

                  if string match -rq \
                          '(?i)^snippets/.+\.css$' \
                          "$repository_path"

                      if not contains \
                              "$repository_path" \
                              $repository_auxiliary_paths

                          set --append repository_auxiliary_paths \
                              "$repository_path"
                      end
                  end
              end

              if test (count $repository_auxiliary_paths) -gt 1
                  set use_repository_subfolder 1
              end

              for repository_path in $repository_auxiliary_paths
                  if string match -q '*/*' "$repository_path"
                      set use_repository_subfolder 1
                      break
                  end
              end

              set repository_asset_root "$theme_stage"
              if test "$use_repository_subfolder" -eq 1
                  set repository_asset_root "$theme_stage/repo"
              end

              if test -d "$extracted/release-assets"
                  for release_asset in "$extracted/release-assets"/*
                      set release_asset_name \
                          (basename "$release_asset")

                      if test -e "$theme_stage/$release_asset_name"
                          continue
                      end

                      command cp -f \
                          "$release_asset" \
                          "$theme_stage/$release_asset_name"

                      set saved_files \
                          $saved_files \
                          "$release_asset_name"
                  end
              end

              if test -n "$manifest"; and test -f "$manifest"
                  if not test -r "$theme_stage/manifest.json"; or \
                          not test -s "$theme_stage/manifest.json"; or \
                          not command jq -e . \
                              "$theme_stage/manifest.json" \
                              >/dev/null 2>&1; or \
                          test "$refresh_theme_core" -eq 1
                      __gitdll_replace_theme_core_from_file \
                          "$manifest" \
                          "$theme_stage/manifest.json"
                  end

                  set saved_files manifest.json
              end

              if test -f "$source_theme_css"
                  if not test -r "$theme_stage/theme.css"; or \
                          not test -s "$theme_stage/theme.css"; or \
                          test "$refresh_theme_core" -eq 1
                      __gitdll_replace_theme_core_from_file \
                          "$source_theme_css" \
                          "$theme_stage/theme.css"
                  end

                  set saved_files $saved_files theme.css
              else
                  if not test -r "$theme_stage/theme.css"; or \
                          not test -s "$theme_stage/theme.css"; or \
                          test "$refresh_theme_core" -eq 1
                      __gitdll_replace_theme_core_from_file \
                          "$source_obsidian_css" \
                          "$theme_stage/theme.css"
                  end

                  set saved_files $saved_files theme.css
                  set source_obsidian_css

                  echo "Notice: obsidian.css was saved as theme.css."
              end

              if test -f "$source_obsidian_css"
                  if not test -r "$theme_stage/obsidian.css"; or \
                          not test -s "$theme_stage/obsidian.css"
                      command cp -f \
                          "$source_obsidian_css" \
                          "$theme_stage/obsidian.css"
                  end

                  set saved_files $saved_files obsidian.css
              end

              if test -f "$extracted/main.js"
                  if not test -s "$theme_stage/main.js"
                      command cp -f "$extracted/main.js" "$theme_stage/main.js"
                  end
                  set saved_files $saved_files main.js
              end

              # Save only supported screenshot files, preserving their exact
              # repository-relative paths. This downloads individual files via
              # the GitHub contents API and never an archive.

              for repository_image_path in $repository_image_paths

                  set repository_image_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$repository_image_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -z "$repository_image_url"
                      continue
                  end

                  set image_destination "$repository_asset_root/$repository_image_path"
                  if test -s "$image_destination"
                      continue
                  end

                  command mkdir -p (dirname "$image_destination")

                  if command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$image_destination" \
                          "$repository_image_url"

                      set saved_files \
                          $saved_files \
                          (string replace "$theme_stage/" "" -- "$image_destination")
                  else
                      echo \
                          "Notice: Could not download theme screenshot: $repository_image_path"
                  end
              end

              # Repository snippets remain in repo/snippets/. Only CSS files are
              # selected, and each is fetched individually from GitHub.
              for snippet_path in $repository_paths
                  if not string match -rq '(?i)^snippets/.+\.css$' "$snippet_path"
                      continue
                  end

                  set snippet_url (
                      command gh api \
                          "repos/$repository_owner/$repository_name/contents/$snippet_path" \
                          --jq .download_url \
                          2>/dev/null
                  )

                  if test -z "$snippet_url"
                      continue
                  end

                  set snippet_destination \
                      "$repository_asset_root/$snippet_path"

                  if test -s "$snippet_destination"
                      continue
                  end

                  command mkdir -p \
                      (dirname "$snippet_destination")

                  if command curl \
                          --fail \
                          --location \
                          --silent \
                          --show-error \
                          --output "$snippet_destination" \
                          "$snippet_url"

                      set saved_files \
                          $saved_files \
                          "repo/$snippet_path"
                  end
              end

              # Preserve supported repository documentation and assets under repo/
              # while keeping their complete repository-relative paths.
              for auxiliary_path in $repository_paths
                  # Repository images were already handled by the dedicated image
                  # loop above.
                  if contains "$auxiliary_path" $repository_image_paths
                      continue
                  end

                  set auxiliary_path_supported 0

                  set auxiliary_name \
                      (basename "$auxiliary_path")

                  # Preserve every file inside documentation folders because
                  # supporting scripts and other files may be required by docs.
                  if string match -rq \
                          '(?i)(^|/)(doc|docs|documentation|wiki)/' \
                          "$auxiliary_path"

                      set auxiliary_path_supported 1

                  # Preserve Markdown and OrgMode files regardless of folder name.
                  else if string match -rq \
                          '(?i)\.(md|markdown|org)$' \
                          "$auxiliary_path"; and \
                          not string match -rq \
                          '(?i)^README(?:\.(md|markdown|org|txt))?$' \
                          "$auxiliary_name"

                      set auxiliary_path_supported 1

                  # Preserve repository image folders such as screenshots/,
                  # images/, previews/, and assets/.
                  else if string match -rq \
                          '(?i)(^|/)[^/]*(assets|gallery|galleries|img|imgs|images|image|screenshots|screenshot|previews|preview)[^/]*/.*\.(png|jpe?g|gif|webp)$' \
                          "$auxiliary_path"

                      set auxiliary_path_supported 1

                  # Preserve screenshot/preview-style images even when their
                  # containing folder has an unrelated name.
                  else if string match -rq \
                          '(?i)(screen|screencap|screenshot|image|preview).*?\.(png|jpe?g|gif|webp)$' \
                          "$auxiliary_name"

                      set auxiliary_path_supported 1
                  end

                  if test "$auxiliary_path_supported" -eq 0
                      continue
                  end

                  set auxiliary_destination \
                      "$repository_asset_root/$auxiliary_path"

                  if test -s "$auxiliary_destination"
                      continue
                  end

                  command mkdir -p \
                      (dirname "$auxiliary_destination")

                  if command gh api \
                          -H "Accept: application/vnd.github.raw+json" \
                          "repos/$repository_owner/$repository_name/contents/$auxiliary_path" \
                          >"$auxiliary_destination" \
                          2>/dev/null; and \
                          test -s "$auxiliary_destination"

                      set saved_files \
                          $saved_files \
                          "repo/$auxiliary_path"
                  else
                      command rm -f \
                          "$auxiliary_destination"

                      echo \
                          "Notice: Could not download theme repository file: $auxiliary_path"
                  end
              end

              # Once anything auxiliary has been saved under repo/, README and
              # repository assets belong there as well.
              if test -d "$theme_stage/repo"; and \
                      command find "$theme_stage/repo" \
                      -mindepth 1 \
                      -print \
                      -quit | read --local existing_repo_content

                  set repository_asset_root \
                      "$theme_stage/repo"
              end

              if test -n "$readme"; and test -f "$readme"
                  set readme_extension (
                      string match -r \
                          '\.[^.]+$' \
                          (basename "$readme")
                  )

                  set readme_output README

                  if test -n "$readme_extension"
                      set readme_output \
                          "README$readme_extension"
                  end

                  # Migrate a root README when auxiliary content activates repo/.
                  if test "$repository_asset_root" = "$theme_stage/repo"; and \
                          test -e "$theme_stage/$readme_output"; and \
                          not test -e "$repository_asset_root/$readme_output"

                      command mkdir -p \
                          "$repository_asset_root"

                      command mv \
                          "$theme_stage/$readme_output" \
                          "$repository_asset_root/$readme_output"
                  end

                  if not test -e "$repository_asset_root/$readme_output"
                      command mkdir -p \
                          "$repository_asset_root"

                      command cp -f \
                          "$readme" \
                          "$repository_asset_root/$readme_output"
                  end

                  set saved_files \
                      $saved_files \
                      (string replace "$theme_stage/" "" -- "$repository_asset_root/$readme_output")

                  set readme_directory (dirname "$readme")
                  set readme_contents (command cat "$readme")

                  set image_references (
                      string match -ra \
                          --groups-only \
                          '!\[[^]]*\]\(\s*<?([^ >)]+)' \
                          -- \
                          $readme_contents
                  )

                  set image_references \
                      $image_references \
                      (
                          string match -ria \
                              --groups-only \
                              "<img[^>]+src=[\"']([^\"']+)" \
                              -- \
                              $readme_contents
                  )

                  set seen_images

                  for image_reference in $image_references
                      if contains \
                              -- \
                              "$image_reference" \
                              $seen_images

                          continue
                      end

                      set seen_images \
                          $seen_images \
                          "$image_reference"

                      set image_path (
                          string replace -r \
                              '[?#].*$' \
                              ''' \
                              "$image_reference"
                      )

                      if string match -rq \
                              '^https?://' \
                              "$image_path"

                          # Remote README images have no trustworthy repository-
                          # relative destination. The repository scan above saves
                          # the supported local screenshot paths unchanged.
                          continue
                      else if not string match -rq \
                              '(^|/)\.\.(/|$)' \
                              "$image_path"; and \
                              not string match -rq \
                              '^/' \
                              "$image_path"

                          set local_image \
                              "$readme_directory/$image_path"

                          if test -f "$local_image"
                              set relative_image_path (
                                  string replace "$extracted/" "" -- "$local_image"
                              )
                              set local_parent \
                                  (dirname "$relative_image_path")

                              command mkdir -p \
                                  "$repository_asset_root/$local_parent"

                              if not test -f "$repository_asset_root/$relative_image_path"
                                  command cp -f \
                                      "$local_image" \
                                      "$repository_asset_root/$relative_image_path"
                              end

                              set saved_files \
                                  $saved_files \
                                  (string replace "$theme_stage/" "" -- "$repository_asset_root/$relative_image_path")
                          else
                              echo \
                                  "Notice: README preview image was not found in the repository: $image_reference"
                          end
                      else
                          echo \
                              "Notice: Skipping unsafe README image path: $image_reference"
                      end
                  end
              else
                  echo "Notice: No README file was found."
              end

              if not test -s "$theme_stage/manifest.json"; or \
                  not command jq -e 'type == "object"' "$theme_stage/manifest.json" >/dev/null 2>&1
                  if not command jq -n \
                          --arg name "$theme_folder_name" \
                          --arg author "$repository_owner" \
                          --arg url "$canonical_repository_url" \
                          '{
                              name: $name,
                              author: $author,
                              version: "0.0.0",
                              minAppVersion: "0.0.0",
                              themeUrl: $url,
                              generatedManifest: true
                          }' \
                          >"$theme_stage/manifest.json"
                      echo "Error: Could not generate manifest.json."
                      command rm -rf -- "$temporary_directory"
                      continue
                  end

                  set saved_files $saved_files manifest.json
              end

              if not command jq \
                      --arg url "$canonical_repository_url" \
                      '.themeUrl = $url' \
                      "$theme_stage/manifest.json" \
                      >"$theme_stage/manifest.json.gitdll-new"; or \
                      not command mv \
                      -- \
                      "$theme_stage/manifest.json.gitdll-new" \
                      "$theme_stage/manifest.json"
                  command rm -f -- "$theme_stage/manifest.json.gitdll-new"
                  echo "Error: Could not save themeUrl in manifest.json."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              __obsidian_normalize_download_layout "$theme_stage"

              if test "$theme_directory_exists" -eq 1
                  echo "Updated:"
                  echo "  $theme_directory"
              else if not command mv \
                      -- \
                      "$theme_stage" \
                      "$theme_directory"

                  echo "Error: Could not save the theme directory."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              echo "Saved:"
              echo "  $theme_directory"

              echo "Files:"

              for saved_file in $saved_files
                  echo "  $saved_file"
              end

              command rm -rf -- "$temporary_directory"
          end
        '';
      };
      # -----------------------------------------------------------------

      # -----------------------------------------------------------------
      # ---- ia -> Internet Archive helper through Python ---- #
      # Download Internet Archive files by type
      #
      # Examples:
      # ia dll https://archive.org/details/NARA-26300439
      # ia dll pdf https://archive.org/details/NARA-26300439
      # ia dll epub https://archive.org/details/NARA-26300439
      # -----------------------------------------------------------------
      ia = ''
        # Check if any arguments were provided; if not, display usage instructions and return an error
        if test (count $argv) -eq 0

        	# Display usage instructions for the ia function
          echo "Usage:"
          echo "  ia dll <archive-url-or-id>"
          echo "  ia dll pdf <archive-url-or-id>"
          echo "  ia dll epub <archive-url-or-id>"
          return 1
        end

        # Process the provided arguments and determine the action to take
        switch $argv[1]
          case dll
            set filetype pdf
            set target ""

            # If count $argv is 2, set target based on the provided argument
            if test (count $argv) -eq 2
              set target $argv[2]

            # Count $argv is 3 or more, set filetype and target based on the provided arguments
            else if test (count $argv) -ge 3
              set filetype $argv[2]
              set target $argv[3]
            else
            	# If the arguments are insufficient, display usage instructions and return an error
              echo "Usage: ia dll [pdf|epub] <archive-url-or-id>"
              return 1
            end

            # ** NOTE: '$argv' means the second argument provided to the function, which is expected to be the archive URL or ID. This value is assigned to the variable 'target' for further processing.


            # Remove leading dot from filetype if present
            set filetype (string replace -r '^\\.' "" "$filetype")

            # Extract the identifier from the provided target URL or ID for Internet Archive downloads
            if string match -q '*archive.org/details/*' "$target"


              # Extract the identifier from the URL using a regular expression to capture the part after 'details/' and before any query parameters or fragments
              set identifier (string replace -r '^.*archive\\.org/details/([^/?#]+).*$' '$1' "$target")
            else if string match -q '*archive.org/download/*' "$target"

              # Extract the identifier from the URL using a regular expression to capture the part after 'download/' and before any query parameters or fragments
              set identifier (string replace -r '^.*archive\\.org/download/([^/?#]+).*$' '$1' "$target")
            else

            	# If the target is not a recognized Internet Archive URL, assume it is an identifier and use it directly
              set identifier "$target"
            end

            # Display the download information
            echo "Downloading .$filetype files from:"
            echo "$identifier"

            # Use the Internet Archive command-line tool to download files of the specified type from the identified archive
            command ia download "$identifier" "--glob=*.$filetype"

          case '*'
          command ia $argv
        end
      '';
      # -----------------------------------------------------------------

      # -----------------------------------------------------------------
      # ---- obsidian-missing -> Migrate and restore manifest repository URLs ---- #
      # -----------------------------------------------------------------
      obsidian-missing = {
        description = "Migrate and restore Obsidian manifest repository URLs";

        body = ''
          if test (count $argv) -ne 1
            echo "Usage:"
            echo '  obsidian-missing "library path"'
            return 1
          end

          set --local library_root "$argv[1]"

          if not test -d "$library_root"
            echo "Error: Library directory does not exist:"
            echo "  $library_root"
            return 1
          end

          if not command -q gh
            echo "Error: gh is not installed."
            return 1
          end

          if not command -q jq
            echo "Error: jq is not installed."
            return 1
          end

          if not command -q curl
            echo "Error: curl is not installed."
            return 1
          end

          if not command -q base64
            echo "Error: base64 is not installed."
            return 1
          end

          if not command -q node
            echo "Error: node is not installed."
            return 1
          end

          # Normalize GitHub URLs before they are stored in a manifest field.
          function __obsidian_missing_canonical_repository_url --argument-names repository_url
            set --local repository (
              string replace -r '^(?:https?://)?(?:www\\.)?github\\.com/' "" -- "$repository_url" |
              string replace -r '\\.git/?$' "" |
              string trim --chars=/
            )

            if not string match -rq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$repository"
              return 1
            end
            printf 'https://github.com/%s\n' "$repository"
          end

          # Write only a verified GitHub URL to the relevant manifest field. A
          # temporary sibling file prevents a failed lookup from truncating it.
          function __obsidian_missing_save_repository_url \
              --argument-names manifest_file url_field repository_url

            if not string match -rq '^https://github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$repository_url"
              return 1
            end

            if test -L "$manifest_file"
              echo "Error: Refusing to replace symlinked manifest.json: $manifest_file"
              return 1
            end

            set --local staging_file "$manifest_file.obsidian-missing-new"

            if not command jq \
                --arg field "$url_field" \
                --arg url "$repository_url" \
                '.[$field] = $url' \
                "$manifest_file" >"$staging_file"
              command rm -f -- "$staging_file"
              return 1
            end

            if not command mv -- "$staging_file" "$manifest_file"
              command rm -f -- "$staging_file"
              return 1
            end
          end

          # Move legacy metadata to Trash only after the manifest write succeeds.
          # Finder owns the Darwin path; the feature-installed trash-cli command
          # owns the Linux/NixOS path. Neither branch falls back to rm.
          function __obsidian_missing_trash_legacy_url --argument-names legacy_file
            if not test -e "$legacy_file"; and not test -L "$legacy_file"
              return 0
            end

            ${legacyTrashCommand}
          end

          # Check whether a manifest remains usable by Obsidian before trusting it.
          function __obsidian_missing_manifest_is_healthy --argument-names manifest_file
            test -f "$manifest_file"; and \
              test -s "$manifest_file"; and \
              not test -L "$manifest_file"; and \
              command jq -e 'type == "object"' "$manifest_file" >/dev/null 2>&1
          end

          # JavaScript syntax must be valid before a plugin payload is reused.
          function __obsidian_missing_javascript_is_healthy --argument-names script_file
            test -f "$script_file"; and \
              test -s "$script_file"; and \
              not test -L "$script_file"; and \
              command node --check "$script_file" >/dev/null 2>&1
          end

          # CSS has no standalone parser in this command's dependency set. Check
          # the structural errors that would otherwise leave Obsidian with a
          # broken stylesheet: unclosed strings/comments and unbalanced braces.
          function __obsidian_missing_stylesheet_is_healthy --argument-names stylesheet_file
            if not test -f "$stylesheet_file"; or \
                not test -s "$stylesheet_file"; or \
                test -L "$stylesheet_file"
              return 1
            end

            command node -e '
              const fs = require("node:fs");
              const source = fs.readFileSync(process.argv[1], "utf8");
              let depth = 0;
              let quote = "";
              let escaped = false;
              let comment = false;
              for (let index = 0; index < source.length; index += 1) {
                const character = source[index];
                const next = source[index + 1] || "";
                if (comment) {
                  if (character === "*" && next === "/") {
                    comment = false;
                    index += 1;
                  }
                  continue;
                }
                if (quote) {
                  if (escaped) {
                    escaped = false;
                  } else if (character.charCodeAt(0) === 92) {
                    escaped = true;
                  } else if (character === quote) {
                    quote = "";
                  }
                  continue;
                }
                if (character === "/" && next === "*") {
                  comment = true;
                  index += 1;
                } else if (character.charCodeAt(0) === 34 || character.charCodeAt(0) === 39) {
                  quote = character;
                } else if (character === "{") {
                  depth += 1;
                } else if (character === "}") {
                  depth -= 1;
                  if (depth < 0) process.exit(1);
                }
              }
              if (comment || quote || depth !== 0) process.exit(1);
            ' "$stylesheet_file" >/dev/null 2>&1
          end

          # Release assets are authoritative for Obsidian's compiled files.
          # Repository contents are used only when the newest release does not
          # provide the requested file.
          function __obsidian_missing_release_asset_url \
              --argument-names repository asset_name
            set --local release_assets (
              command gh api \
                "repos/$repository/releases/latest" \
                --jq '.assets[]? | [.name, .browser_download_url] | @tsv' \
                2>/dev/null
            )

            for release_asset in $release_assets
              set --local release_parts (string split \t "$release_asset")
              if test (count $release_parts) -ge 2; and \
                  test "$release_parts[1]" = "$asset_name"
                printf '%s\n' "$release_parts[2]"
                return 0
              end
            end

            return 1
          end

          # Download a file only when a healthy destination does not already exist.
          function __obsidian_missing_download_url \
              --argument-names destination download_url description replace_existing

            if test -L "$destination"
              echo "Notice: Refusing to replace symlinked file: $destination"
              return 1
            end

            if test -f "$destination"; and \
                test -s "$destination"; and \
                test "$replace_existing" != yes
              return 0
            end

            # Empty files can be removed before download. Healthy files requested
            # for replacement stay intact until the staged download is complete.
            if test -e "$destination"; and test "$replace_existing" != yes
              command rm -f -- "$destination"
            end

            set --local destination_parent (dirname "$destination")

            if not command mkdir -p -- "$destination_parent"
              echo "Notice: Could not create destination folder: $destination_parent"
              return 1
            end

            set --local staging_file \
              "$destination.obsidian-missing-new"

            if not command curl \
                --fail \
                --location \
                --silent \
                --show-error \
                --output "$staging_file" \
                "$download_url"; or \
                not test -s "$staging_file"; or \
                not command mv -- "$staging_file" "$destination"

              command rm -f -- "$staging_file"
              echo "Notice: Could not restore $description"
              return 1
            end

            echo "Saved $destination"
          end

          # Omit localized README variants and non-ASCII repository paths. The
          # GitHub contents endpoint requires encoded paths, while these files
          # are intentionally outside the permanent Obsidian library scope.
          function __obsidian_missing_path_is_unsupported --argument-names repository_path
            if not string match -rq '^[\x00-\x7F]+$' "$repository_path"
              return 0
            end

            if __obsidian_download_path_blocked "$repository_path"
              return 0
            end

            set --local filename \
              (string lower -- (basename "$repository_path"))

            string match -rq \
              '(?i)^readme(?:[-_.][a-z]{2,3}(?:[-_][a-z0-9]+)*)+(?:\.(md|markdown|org|txt))?$' \
              "$filename"
          end

          # Restore or migrate README according to the entry's auxiliary-content
          # layout. Core Obsidian files remain at root; auxiliary content uses repo/.
          function __obsidian_missing_restore_readme \
              --argument-names library_entry repository_url

            set --local repository (
              string replace -r '^(?:https?://)?(?:www\\.)?github\\.com/' "" -- "$repository_url" |
              string replace -r '\\.git$' ""
            )

            if not string match -rq \
                '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' \
                "$repository"

              echo "Notice: Could not restore README for $library_entry; repository URL is invalid."
              return 1
            end

            set --local readme_metadata (
              command gh api \
                "repos/$repository/readme" \
                --jq '[.name, .size, .download_url] | @tsv' \
                2>/dev/null
            )

            if test $status -ne 0; or test -z "$readme_metadata"
              echo "Notice: Repository has no downloadable README: $repository"
              return 1
            end

            set --local readme_parts \
              (string split \t "$readme_metadata")

            if test (count $readme_parts) -ne 3
              echo "Notice: Could not read repository README metadata: $repository"
              return 1
            end

            set --local readme_name \
              "$readme_parts[1]"

            if __obsidian_missing_path_is_unsupported "$readme_name"
              return 0
            end

            set --local readme_size \
              "$readme_parts[2]"

            set --local readme_url \
              "$readme_parts[3]"

            # Repository auxiliary files have already been normalized before this
            # helper runs. README only needs to follow the resulting local layout.
            set --local use_repository_subfolder 0

            if test -d "$library_entry/repo"; and \
                command find "$library_entry/repo" \
                  -mindepth 1 \
                  -print \
                  -quit | read --local existing_repo_content

              # An existing repo/ is deliberate layout state. Keeping it active
              # prevents a later repair from flattening and re-downloading it.
              set use_repository_subfolder 1
            end

            set --local readme_root \
              "$library_entry"

            if test "$use_repository_subfolder" -eq 1
              set readme_root \
                "$library_entry/repo"
            end

            set --local readme_destination \
              "$readme_root/$readme_name"

            if test -f "$readme_destination"; and test -s "$readme_destination"
              set --local destination_size (command stat -f %z -- "$readme_destination")

              if test "$destination_size" = "$readme_size"
                return 0
              end

              if test "$readme_root" = "$library_entry/repo"
                echo "README differs from the repository version: $readme_destination"
                echo "  local size: $destination_size bytes"
                echo "  remote size: $readme_size bytes"
                read --prompt-str "Replace repo README (r) or keep both (b)? " readme_choice

                if test "$readme_choice" = r; or test "$readme_choice" = R
                  __obsidian_missing_download_url \
                    "$readme_destination" \
                    "$readme_url" \
                    "$readme_name" \
                    yes
                  return $status
                end

                if test "$readme_choice" = b; or test "$readme_choice" = B
                  set --local root_readme_destination \
                    "$library_entry/$readme_name"

                  if test -f "$root_readme_destination"; and \
                      test -s "$root_readme_destination"
                    echo "Keeping the existing root and repo READMEs."
                    return 0
                  end

                  __obsidian_missing_download_url \
                    "$root_readme_destination" \
                    "$readme_url" \
                    "$readme_name"
                  return $status
                end

                echo "Leaving the existing repo README unchanged."
                return 0
              end
            end

            set --local existing_readme (
              command find "$library_entry" \
                -type f \
                \( \
                  -iname README \
                  -o -iname README.md \
                  -o -iname README.markdown \
                  -o -iname README.org \
                  -o -iname README.txt \
                \) \
                -size "$readme_size"c \
                -print \
                -quit \
                2>/dev/null
            )

            if test -n "$existing_readme"
              # README already exists, but auxiliary mode may require relocating it.
              if test "$readme_root" = "$library_entry/repo"; and \
                  not string match -q "$library_entry/repo/*" "$existing_readme"

                command mkdir -p \
                  "$library_entry/repo"

                if not test -e "$readme_destination"
                  command mv \
                    "$existing_readme" \
                    "$readme_destination"
                end
              end

              return 0
            end

            __obsidian_missing_download_url \
              "$readme_destination" \
              "$readme_url" \
              "$readme_name"
          end

          # Restore missing theme images using the same root/repo placement rules
          # as gitdll --themes.
          function __obsidian_missing_restore_theme_screenshots \
              --argument-names library_entry repository_url

            set --local repository (
              string replace -r '^(?:https?://)?(?:www\\.)?github\\.com/' "" -- "$repository_url" |
              string replace -r '\\.git$' ""
            )

            if not string match -rq \
                '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' \
                "$repository"

              return 1
            end

            set --local repository_paths (
              command gh api \
                "repos/$repository/git/trees/HEAD?recursive=1" \
                --jq '.tree[]? | select(.type == "blob") | .path' \
                2>/dev/null
            )

            if test $status -ne 0
              echo "Notice: Could not inspect theme images for $library_entry"
              return 1
            end

            set --local repository_image_paths
            set --local use_repository_subfolder 0

            for repository_path in $repository_paths
              set --local repository_image_name \
                (basename "$repository_path")

              if string match -rq \
                  '(^|/)\.[^/]+' \
                  "$repository_path"; or \
                  string match -rq \
                  '(^|/)node_modules/' \
                  "$repository_path"; or \
                  __obsidian_missing_path_is_unsupported \
                      "$repository_path"; or \
                  __obsidian_download_name_blocked \
                      "$repository_image_name"

                continue
              end

              set --local is_root_image 0
              set --local has_image_keyword 0
              set --local is_image_folder_image 0

              if not string match -q '*/*' "$repository_path"; and \
                  string match -rq \
                  '(?i)\.(png|jpe?g|gif|webp)$' \
                  "$repository_image_name"

                set is_root_image 1
              end

              if string match -rq \
                  '(?i)(screen|screencap|screenshot|image|preview|previews).*?\.(png|jpe?g|gif|webp)$' \
                  "$repository_image_name"

                set has_image_keyword 1
              end

              if string match -rq \
                  '(?i)(^|/)[^/]*(asset|assets|gallery|galleries|img|imgs|image|images|preview|previews|screenshot|screenshots)[^/]*/.*\.(png|jpe?g|gif|webp)$' \
                  "$repository_path"

                set is_image_folder_image 1
              end

              if test "$is_root_image" -eq 0; and \
                  test "$has_image_keyword" -eq 0; and \
                  test "$is_image_folder_image" -eq 0

                continue
              end

              set --append repository_image_paths \
                "$repository_path"

              if string match -q '*/*' "$repository_path"
                set use_repository_subfolder 1
              end
            end

            if test (count $repository_image_paths) -gt 1
              set use_repository_subfolder 1
            end

            set --local repository_asset_root \
              "$library_entry"

            if test "$use_repository_subfolder" -eq 1
              set repository_asset_root \
                "$library_entry/repo"
            end

            for repository_image_path in $repository_image_paths
              set --local destination \
                "$repository_asset_root/$repository_image_path"

              if test -e "$destination"; or test -L "$destination"
                continue
              end

              set --local checked_path \
                "$repository_asset_root"

              set --local unsafe_path 0

              for component in (string split / "$repository_image_path")
                set checked_path \
                  "$checked_path/$component"

                if test -L "$checked_path"
                  echo "Notice: Refusing to write through symlinked theme path: $checked_path"
                  set unsafe_path 1
                  break
                end
              end

              if test "$unsafe_path" -eq 1
                continue
              end

              set --local image_metadata (
                command gh api \
                  "repos/$repository/contents/$repository_image_path" \
                  --jq '[.size, .download_url] | @tsv' \
                  2>/dev/null
              )

              if test -z "$image_metadata"
                echo "Notice: Could not resolve theme image: $repository_image_path"
                continue
              end

              set --local image_parts \
                (string split \t "$image_metadata")

              if test (count $image_parts) -ne 2
                echo "Notice: Could not read theme image metadata: $repository_image_path"
                continue
              end

              set --local image_size \
                "$image_parts[1]"

              set --local image_url \
                "$image_parts[2]"

              set --local image_name \
                (basename "$repository_image_path")

              if command find "$library_entry" \
                  -type f \
                  -iname "$image_name" \
                  -size "$image_size"c \
                  -print \
                  -quit \
                  2>/dev/null | read --local existing_image

                continue
              end

              __obsidian_missing_download_url \
                "$destination" \
                "$image_url" \
                "$repository_image_path"
            end
          end

          # Restore all standard files that the normal plugin/theme downloaders
          # would keep. Release assets are preferred before repository fallback.
          function __obsidian_missing_restore_standard_files \
              --argument-names library_entry repository_url requires_plugin_payload

            set --local repository (
              string replace -r '^(?:https?://)?(?:www\\.)?github\\.com/' "" -- "$repository_url" |
              string replace -r '\\.git$' ""
            )

            if not string match -rq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$repository"
              echo "Notice: Could not restore files for $library_entry; repository URL is invalid."
              return 1
            end

            # Fetch repository file paths using the same mechanism as gitdll.
            set --local repository_paths (
              command gh api \
                "repos/$repository/git/trees/HEAD?recursive=1" \
                --jq '.tree[]? | select(.type == "blob") | .path' \
                2>/dev/null
            )

            set --local use_repository_subfolder 0

            if test -d "$library_entry/repo"; and \
                command find "$library_entry/repo" \
                  -mindepth 1 \
                  -print \
                  -quit | read --local existing_repo_content

              # Keep an already-grouped repository layout stable during repair.
              set use_repository_subfolder 1
            end

            set --local release_assets
            set --local release_json (
              command gh api \
                "repos/$repository/releases/latest" \
                2>/dev/null
            )

            if test $status -eq 0; and test -n "$release_json"
              set release_assets (
                printf '%s' "$release_json" |
                command jq -r \
                  '.assets[]?
                  | [.name, .browser_download_url]
                  | @tsv'
              )
            end

            # A missing, empty, or malformed manifest—or missing main.js—means
            # Obsidian cannot load a plugin. Refresh every available core file as
            # one payload instead of preserving a stale mix of old and new files.
            set --local refresh_core_payload 0

            if test "$requires_plugin_payload" -eq 1
              set --local plugin_stylesheet_is_healthy 1

              if test -e "$library_entry/styles.css"; and \
                  not __obsidian_missing_stylesheet_is_healthy \
                    "$library_entry/styles.css"
                set plugin_stylesheet_is_healthy 0
              end

              if not __obsidian_missing_manifest_is_healthy \
                  "$library_entry/manifest.json"; or \
                  not __obsidian_missing_javascript_is_healthy \
                    "$library_entry/main.js"; or \
                  test "$plugin_stylesheet_is_healthy" -eq 0
                set refresh_core_payload 1
              end
            else if not __obsidian_missing_manifest_is_healthy \
                "$library_entry/manifest.json"; or \
                not __obsidian_missing_stylesheet_is_healthy \
                  "$library_entry/theme.css"
              set refresh_core_payload 1
            end

            # Every actual GitHub release asset belongs at the entry root.
            # A library-named ZIP is deferred until standard core recovery has
            # exhausted both the release and the main repository.
            set --local deferred_library_archives

            # GitHub's generated source archives are not members of .assets[].
            for release_asset in $release_assets
              set --local release_parts \
                (string split \t "$release_asset")

              if test (count $release_parts) -lt 2
                continue
              end

              set --local release_asset_name \
                "$release_parts[1]"

              set --local release_asset_url \
                "$release_parts[2]"

                if __obsidian_missing_path_is_unsupported \
                    "$release_asset_name"; or \
                    __obsidian_download_name_blocked \
                    "$release_asset_name"

                  continue
                end

              if __obsidian_is_named_release_archive \
                  "$release_asset_name" \
                  (basename "$library_entry") \
                  (basename "$repository")
                if string match -ri '\\.zip$' "$release_asset_name"
                  set --append deferred_library_archives \
                    "$release_asset"
                end
                continue
              end

              __obsidian_missing_download_url \
                "$library_entry/$release_asset_name" \
                "$release_asset_url" \
                "$release_asset_name"
            end

            if test "$requires_plugin_payload" -eq 1
              # Plugins keep all load-bearing files at their root. data.json and
              # styles.css remain optional upstream, but refresh when supplied.
              for expected_file in manifest.json main.js styles.css data.json
                set --local destination \
                  "$library_entry/$expected_file"

                if test -s "$destination"; and \
                    test "$refresh_core_payload" -eq 0
                  continue
                end

                set --local release_url

                for release_asset in $release_assets
                  set --local release_parts \
                    (string split \t "$release_asset")

                  if test (count $release_parts) -lt 2
                    continue
                  end

                  if test "$release_parts[1]" = "$expected_file"
                    set release_url "$release_parts[2]"
                    break
                  end
                end

                if test -n "$release_url"
                  if __obsidian_missing_download_url \
                      "$destination" \
                      "$release_url" \
                      "$expected_file" \
                      yes
                    continue
                  end
                end

                set --local repository_file_path (
                  printf '%s\n' $repository_paths |
                  command awk -F/ \
                    -v expected_file="$expected_file" \
                    '$NF == expected_file { print; exit }'
                )

                if test -z "$repository_file_path"
                  continue
                end

                set --local repository_file_url (
                  command gh api \
                    "repos/$repository/contents/$repository_file_path" \
                    --jq .download_url \
                    2>/dev/null
                )

                if test -z "$repository_file_url"
                  continue
                end

                __obsidian_missing_download_url \
                  "$destination" \
                  "$repository_file_url" \
                  "$expected_file" \
                  yes
              end

            else
              # Themes: restore manifest.json from release before repository.
              if not __obsidian_missing_manifest_is_healthy \
                  "$library_entry/manifest.json"; or \
                  test "$refresh_core_payload" -eq 1
                set --local manifest_release_url

                for release_asset in $release_assets
                  set --local release_parts \
                    (string split \t "$release_asset")

                  if test (count $release_parts) -lt 2
                    continue
                  end

                  if test "$release_parts[1]" = manifest.json
                    set manifest_release_url "$release_parts[2]"
                    break
                  end
                end

                if test -n "$manifest_release_url"
                  __obsidian_missing_download_url \
                    "$library_entry/manifest.json" \
                    "$manifest_release_url" \
                    "manifest.json" \
                    yes
                else
                  set --local manifest_repository_path (
                    printf '%s\n' $repository_paths |
                    command awk -F/ \
                      '$NF == "manifest.json" { print; exit }'
                  )

                  if test -n "$manifest_repository_path"
                    set --local manifest_repository_url (
                      command gh api \
                        "repos/$repository/contents/$manifest_repository_path" \
                        --jq .download_url \
                        2>/dev/null
                    )

                    if test -n "$manifest_repository_url"
                      __obsidian_missing_download_url \
                        "$library_entry/manifest.json" \
                        "$manifest_repository_url" \
                        "manifest.json" \
                        yes
                    end
                  end
                end
              end

              # Themes always store the active stylesheet locally as theme.css.
              if not test -s "$library_entry/theme.css"; or \
                  test "$refresh_core_payload" -eq 1
                set --local theme_css_url
                set --local theme_css_source

                for source_name in theme.css obsidian.css
                  for release_asset in $release_assets
                    set --local release_parts \
                      (string split \t "$release_asset")

                    if test (count $release_parts) -lt 2
                      continue
                    end

                    if test "$release_parts[1]" = "$source_name"
                      set theme_css_source "$source_name"
                      set theme_css_url "$release_parts[2]"
                      break
                    end
                  end

                  if test -n "$theme_css_url"
                    break
                  end
                end

                if test -z "$theme_css_url"
                  for source_name in theme.css obsidian.css
                    set --local repository_css_path (
                      printf '%s\n' $repository_paths |
                      command awk -F/ \
                        -v expected_file="$source_name" \
                        '$NF == expected_file { print; exit }'
                    )

                    if test -z "$repository_css_path"
                      continue
                    end

                    set theme_css_url (
                      command gh api \
                        "repos/$repository/contents/$repository_css_path" \
                        --jq .download_url \
                        2>/dev/null
                    )

                    if test -n "$theme_css_url"
                      set theme_css_source "$source_name"
                      break
                    end
                  end
                end

                if test -n "$theme_css_url"
                  __obsidian_missing_download_url \
                    "$library_entry/theme.css" \
                    "$theme_css_url" \
                    "$theme_css_source" \
                    yes
                end
              end
            end

            # Only restore a library-named distribution ZIP if no usable core
            # could be recovered. styles.css remains separate and is restored
            # above whenever release or repository supplies it.
            set --local library_core_available 0

            if test "$requires_plugin_payload" -eq 1
              if __obsidian_missing_manifest_is_healthy \
                  "$library_entry/manifest.json"; and \
                  __obsidian_missing_javascript_is_healthy \
                    "$library_entry/main.js"
                set library_core_available 1
              end
            else if __obsidian_missing_manifest_is_healthy \
                "$library_entry/manifest.json"; and \
                __obsidian_missing_stylesheet_is_healthy \
                  "$library_entry/theme.css"
              set library_core_available 1
            end

            if test "$library_core_available" -eq 0
              for deferred_library_archive in $deferred_library_archives
                set --local deferred_archive_parts \
                  (string split \t "$deferred_library_archive")

                if test (count $deferred_archive_parts) -lt 2
                  continue
                end

                set --local deferred_archive_name \
                  "$deferred_archive_parts[1]"
                set --local deferred_archive_url \
                  "$deferred_archive_parts[2]"

                __obsidian_missing_download_url \
                  "$library_entry/$deferred_archive_name" \
                  "$deferred_archive_url" \
                  "$deferred_archive_name"
              end
            end

            set --local repository_name \
              (basename "$repository")

            set --local normalized_repository_name (
              string lower -- "$repository_name" |
              string replace -ra '[^0-9a-z]+' ""
            )

            # Build the same repository auxiliary-file set used by gitdll.
            set --local repository_auxiliary_paths

            for auxiliary_path in $repository_paths
              set --local auxiliary_path_supported 0
              set --local auxiliary_name \
                (basename "$auxiliary_path")

              # Ignore hidden folders, dependencies, and blocked filenames.
              if string match -rq \
                  '(^|/)\.[^/]+' \
                  "$auxiliary_path"; or \
                  string match -rq \
                  '(^|/)node_modules/' \
                  "$auxiliary_path"; or \
                  __obsidian_missing_path_is_unsupported \
                      "$auxiliary_path"; or \
                  __obsidian_download_path_blocked \
                      "$auxiliary_path"

                continue
              end

              # Preserve every file inside documentation folders.
              if string match -rq \
                  '(?i)(^|/)(doc|docs|documentation|wiki)/' \
                  "$auxiliary_path"

                set auxiliary_path_supported 1

              # Preserve Markdown and OrgMode files regardless of folder name.
              else if string match -rq \
                  '(?i)\.(md|markdown|org)$' \
                  "$auxiliary_path"; and \
                  not string match -rq \
                  '(?i)^README(?:\.(md|markdown|org|txt))?$' \
                  "$auxiliary_name"

                set auxiliary_path_supported 1

              else if string match -rq \
                  '(?i)(^|/)[^/]*(assets|gallery|galleries|img|imgs|images|image|screenshots|screenshot|previews|preview)[^/]*/.*\.(png|jpe?g|gif|webp)$' \
                  "$auxiliary_path"

                set auxiliary_path_supported 1

              else if string match -rq \
                  '(?i)(screen|screencap|screenshot|image|preview).*?\.(png|jpe?g|gif|webp)$' \
                  "$auxiliary_name"

                set auxiliary_path_supported 1

              # Themes also preserve supported images whose filename contains the
              # normalized repository/theme name.
              else if test "$requires_plugin_payload" -eq 0; and \
                  string match -rq \
                  '(?i)\.(png|jpe?g|gif|webp)$' \
                  "$auxiliary_name"

                set --local normalized_auxiliary_name (
                  string replace -r \
                    '\.[^.]+$' \
                    "" \
                    "$auxiliary_name" |
                  string lower |
                  string replace -ra '[^0-9a-z]+' ""
                )

                if test -n "$normalized_repository_name"; and \
                    string match -q \
                    "*$normalized_repository_name*" \
                    "$normalized_auxiliary_name"

                  set auxiliary_path_supported 1
                end
              end

              # Themes additionally preserve CSS snippets.
              if test "$requires_plugin_payload" -eq 0; and \
                  string match -rq \
                  '(?i)^snippets/.+\.css$' \
                  "$auxiliary_path"

                set auxiliary_path_supported 1
              end

              if test "$auxiliary_path_supported" -eq 1
                set --append repository_auxiliary_paths \
                  "$auxiliary_path"
              end
            end

            set --local use_repository_subfolder 0

            if test (count $repository_auxiliary_paths) -gt 1
              set use_repository_subfolder 1
            end

            for auxiliary_path in $repository_auxiliary_paths
              if string match -q '*/*' "$auxiliary_path"
                set use_repository_subfolder 1
                break
              end
            end

            # Existing repo/ content is already a deliberate grouped layout.
            # Never flatten it during repair, even when it currently holds one
            # auxiliary file, because that would cause a needless re-download.
            if test -d "$library_entry/repo"; and \
                command find "$library_entry/repo" \
                  -mindepth 1 \
                  -print \
                  -quit | read --local existing_repo_content

              set use_repository_subfolder 1
            end

            for auxiliary_path in $repository_auxiliary_paths
              set --local auxiliary_metadata (
                command gh api \
                  "repos/$repository/contents/$auxiliary_path" \
                  --jq '[.size, .download_url] | @tsv' \
                  2>/dev/null
              )

              if test -z "$auxiliary_metadata"
                echo "Notice: Could not resolve repository file: $auxiliary_path"
                continue
              end

              set --local auxiliary_parts \
                (string split \t "$auxiliary_metadata")

              if test (count $auxiliary_parts) -ne 2
                echo "Notice: Could not read repository file metadata: $auxiliary_path"
                continue
              end

              set --local auxiliary_size \
                "$auxiliary_parts[1]"

              set --local auxiliary_url \
                "$auxiliary_parts[2]"

              set --local auxiliary_destination \
                "$library_entry/"(basename "$auxiliary_path")

              if test "$use_repository_subfolder" -eq 1
                set auxiliary_destination \
                  "$library_entry/repo/$auxiliary_path"
              end

              if test -f "$auxiliary_destination"; and \
                  test -s "$auxiliary_destination"

                continue
              end

              if test -L "$auxiliary_destination"
                echo "Notice: Refusing to replace symlinked file: $auxiliary_destination"
                continue
              end

              # Reuse an identical existing file instead of downloading it again.
              set --local existing_auxiliary (
                command find "$library_entry" \
                  -type f \
                  -iname (basename "$auxiliary_path") \
                  -size "$auxiliary_size"c \
                  -print \
                  -quit \
                  2>/dev/null
              )

              if test -n "$existing_auxiliary"
                command mkdir -p \
                  (dirname "$auxiliary_destination")

                if test "$existing_auxiliary" != "$auxiliary_destination"
                  command cp \
                    "$existing_auxiliary" \
                    "$auxiliary_destination"
                end

                continue
              end

              __obsidian_missing_download_url \
                "$auxiliary_destination" \
                "$auxiliary_url" \
                "$auxiliary_path"
            end

            __obsidian_missing_restore_readme \
              "$library_entry" \
              "$repository_url"

            set --local manifest_url_field themeUrl

            if test "$requires_plugin_payload" -eq 1
              set manifest_url_field pluginUrl
            end

            # A repository may ship a compiled payload without a manifest. Build
            # the minimum valid Obsidian manifest only after every upstream source
            # has been tried, so an upstream manifest always wins.
            if not __obsidian_missing_manifest_is_healthy "$library_entry/manifest.json"
              set --local repository_owner (string split / "$repository")[1]
              set --local generated_name (basename "$library_entry")
              set --local generated_id "$generated_name"
              set --local generated_version "0.0.0"
              set --local generated_author "$repository_owner"

              if test "$requires_plugin_payload" -eq 1
                set --local package_content (
                  command gh api "repos/$repository/contents/package.json" --jq .content 2>/dev/null | \
                    command tr -d '\n' | command base64 -D 2>/dev/null
                )
                if test -n "$package_content"
                  set --local package_id (
                    printf '%s' "$package_content" | command jq -r \
                      'if (.id | type) == "string" then .id elif (.name | type) == "string" then .name else empty end' | string trim
                  )
                  set --local package_name (
                    printf '%s' "$package_content" | command jq -r \
                      'if (.name | type) == "string" then .name else empty end' | string trim
                  )
                  set --local package_version (
                    printf '%s' "$package_content" | command jq -r \
                      'if (.version | type) == "string" then .version else empty end' | string trim
                  )
                  set --local package_author (
                    printf '%s' "$package_content" | command jq -r \
                      'if (.author | type) == "string" then .author else empty end' | string trim
                  )
                  if test -n "$package_id"; and not string match -rq '[/\\x00]' "$package_id"
                    set generated_id "$package_id"
                  end
                  if test -n "$package_name"; and not string match -rq '[/\\x00]' "$package_name"
                    set generated_name "$package_name"
                  end
                  if test -n "$package_version"
                    set generated_version "$package_version"
                  end
                  if test -n "$package_author"
                    set generated_author "$package_author"
                  end
                end
              end

              set --local generated_manifest "$library_entry/.manifest.json.obsidian-missing-new"
              if test "$requires_plugin_payload" -eq 1
                command jq -n \
                  --arg id "$generated_id" --arg name "$generated_name" \
                  --arg version "$generated_version" --arg author "$generated_author" \
                  --arg url "$repository_url" \
                  '{ id: $id, name: $name, version: $version, minAppVersion: "0.0.0", author: $author, pluginUrl: $url, generatedManifest: true }' \
                  >"$generated_manifest"
              else
                command jq -n \
                  --arg name "$generated_name" --arg author "$generated_author" \
                  --arg url "$repository_url" \
                  '{ name: $name, author: $author, version: "0.0.0", minAppVersion: "0.0.0", themeUrl: $url, generatedManifest: true }' \
                  >"$generated_manifest"
              end

              if test -s "$generated_manifest"
                command mv -- "$generated_manifest" "$library_entry/manifest.json"
              else
                command rm -f -- "$generated_manifest"
              end
            end

            if __obsidian_missing_manifest_is_healthy \
                "$library_entry/manifest.json"
              if not __obsidian_missing_save_repository_url \
                  "$library_entry/manifest.json" \
                  "$manifest_url_field" \
                  "$repository_url"
                echo "Notice: Could not save $manifest_url_field in $library_entry/manifest.json"
              end
            else
              echo "Notice: The restored manifest remains invalid: $library_entry/manifest.json"
            end

            __obsidian_normalize_download_layout "$library_entry"


          end

          set --local missing_entries
          set --local missing_repository_entries
          set --local missing_report "$HOME/Downloads/obsidian-missing.txt"
          set --local library_root_name (
            basename "$library_root" | string lower
          )
          set --local requires_plugin_payload 0
          set --local manifest_url_field themeUrl

          if string match -rq '(plugin|extension)' "$library_root_name"
            set requires_plugin_payload 1
            set manifest_url_field pluginUrl
          end

          # List every entry before looking for a repository URL. Incomplete
          # manifests still appear, and only affect automatic URL resolution.
          printf '%-28s %-20s %-56s %s\n' \
            "ID" \
            "AUTHOR" \
            "DESCRIPTION" \
            "VERSION"

          for library_entry in "$library_root"/*
            if not test -d "$library_entry"
              continue
            end

            set --local entry_name (
              basename "$library_entry"
            )

            set --local manifest_file \
              "$library_entry/manifest.json"

            if not test -f "$manifest_file"
              set manifest_file \
                "$library_entry/repo/manifest.json"
            end

            if not test -f "$manifest_file"
              set --local legacy_manifest_repository_url

              for repository_candidate in \
                  "$library_entry/repository-url.txt" \
                  "$library_entry/repo/repository-url.txt"

                if not test -s "$repository_candidate"
                  continue
                end

                set legacy_manifest_repository_url (
                  string match -r -m 1 \
                    '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' \
                    <"$repository_candidate"
                )

                if test -n "$legacy_manifest_repository_url"
                  set legacy_manifest_repository_url \
                    (__obsidian_missing_canonical_repository_url "$legacy_manifest_repository_url")
                  break
                end
              end

              if test -n "$legacy_manifest_repository_url"
                __obsidian_missing_restore_standard_files \
                  "$library_entry" \
                  "$legacy_manifest_repository_url" \
                  "$requires_plugin_payload"

                set manifest_file \
                  "$library_entry/manifest.json"
              end

              if not test -f "$manifest_file"
                set --append missing_entries \
                  "$entry_name — manifest.json missing and repository could not be resolved"
                continue
              end
            end

            # An explicitly abandoned entry remains on disk for inspection or
            # removal, but is not resolved, migrated, or downloaded again.
            set --local entry_abandoned (
              command jq -r \
                'if type == "object" and .abandoned == "yes" then "yes" else empty end' \
                "$manifest_file" \
                2>/dev/null
            )
            if test "$entry_abandoned" = yes
              continue
            end

            set --local manifest_fields (
              command jq -r \
                'if type == "object" then
                  [(.name // .id // ""), (.author // .authorUrl // ""), (.description // ""), (.version // "")]
                  | map(if type == "string" then . else "" end)
                  | @tsv
                else
                  empty
                end' \
                "$manifest_file"
            )
            set --local manifest_columns (
              string split \t "$manifest_fields"
            )
            set --local table_id
            set --local table_author
            set --local table_description ""
            set --local table_version ""

            if test (count $manifest_columns) -eq 4
              set table_id "$manifest_columns[1]"
              set table_author "$manifest_columns[2]"
              set table_description "$manifest_columns[3]"
              set table_version "$manifest_columns[4]"
            end

            if string match -rq '^https?://[^[:space:]]+$' "$table_author"
              set table_author (
                string replace -r '^https?://(?:www\\.)?' "" -- "$table_author" |
                string replace -r '/+$' "" |
                string split / |
                command tail -n 1
              )
            end
            set table_author (string replace -ra '[[:space:]]+' ' ' -- "$table_author" | string trim)
            set table_description (string replace -ra '[[:space:]]+' ' ' -- "$table_description" | string trim)
            set table_version (string trim -- "$table_version")
            if test -z "$table_id"
              set table_id "$entry_name"
            end
            printf '%-28s %-20s %-56s %s\n' \
              "$table_id" \
              "$table_author" \
              "$table_description" \
              "$table_version"

            set --local manifest_repository_url (
              command jq -r \
                --arg field "$manifest_url_field" \
                'if (.[$field] | type) == "string" then .[$field] else empty end' \
                "$manifest_file" |
              string match -r -m 1 '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?'
            )
            if test -n "$manifest_repository_url"
              set manifest_repository_url (__obsidian_missing_canonical_repository_url "$manifest_repository_url")
            end

            # A broken manifest can still retain its GitHub URL as plain text.
            # Recover it before replacing the manifest during a core repair.
            if test -z "$manifest_repository_url"
              set manifest_repository_url (
                string match -r -m 1 \
                  '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' \
                  <"$manifest_file"
              )

              if test -n "$manifest_repository_url"
                set manifest_repository_url \
                  (__obsidian_missing_canonical_repository_url "$manifest_repository_url")
              end
            end
            set --local legacy_repository_file
            set --local legacy_repository_url
            for repository_candidate in \
                "$library_entry/repository-url.txt" \
                "$library_entry/repo/repository-url.txt"
              if not test -f "$repository_candidate"; or \
                  not test -s "$repository_candidate"
                continue
              end

              set legacy_repository_url (
                string match -r -m 1 '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' <"$repository_candidate"
              )
              if test -n "$legacy_repository_url"
                set legacy_repository_url (__obsidian_missing_canonical_repository_url "$legacy_repository_url")
              end
              if test -n "$legacy_repository_url"
                set legacy_repository_file "$repository_candidate"
                break
              end
            end

            if test -n "$manifest_repository_url"
              if test -n "$legacy_repository_url"; and \
                  test "$manifest_repository_url" != "$legacy_repository_url"
                echo "Repository URL conflict for $entry_name:"
                echo "  manifest $manifest_url_field: $manifest_repository_url"
                echo "  legacy repository-url.txt: $legacy_repository_url"
                read --prompt-str "Use manifest (m) or legacy (l)? " conflict_choice
                if test "$conflict_choice" = l; or test "$conflict_choice" = L
                  if not __obsidian_missing_save_repository_url \
                      "$manifest_file" \
                      "$manifest_url_field" \
                      "$legacy_repository_url"
                    echo "Notice: Could not save the legacy URL into $manifest_file"
                    continue
                  end
                  set manifest_repository_url "$legacy_repository_url"
                else if test "$conflict_choice" != m; and test "$conflict_choice" != M
                  echo "Skipping unresolved URL conflict: $entry_name"
                  continue
                end
              end

              if test -n "$legacy_repository_file"
                __obsidian_missing_trash_legacy_url "$legacy_repository_file"
              end
              __obsidian_missing_restore_standard_files \
                "$library_entry" \
                "$manifest_repository_url" \
                "$requires_plugin_payload"

              continue
            end

            if test -n "$legacy_repository_url"
              if not __obsidian_missing_save_repository_url \
                  "$manifest_file" \
                  "$manifest_url_field" \
                  "$legacy_repository_url"
                echo "Notice: Could not migrate $entry_name"
                set --append missing_repository_entries "$entry_name"
                continue
              end
              __obsidian_missing_trash_legacy_url "$legacy_repository_file"

              __obsidian_missing_restore_standard_files \
                "$library_entry" \
                "$legacy_repository_url" \
                "$requires_plugin_payload"

              continue
            end

            set --append missing_repository_entries "$entry_name"

            set --local library_id (
              command jq -r \
                'if type == "object" then
                  if (.id | type) == "string" then .id else empty end
                else
                  empty
                end' \
                "$manifest_file" |
              string trim
            )

            set --local author (
              command jq -r \
                'if (.author | type) == "string" then .author else empty end' \
                "$manifest_file" |
              string trim
            )

            set --local author_url (
              command jq -r \
                'if (.authorUrl | type) == "string" then .authorUrl else empty end' \
                "$manifest_file" |
              string trim
            )

            if test -z "$library_id"
              set library_id "$entry_name"
            end

            set --local author_url_owner (
              string match -r -g \
                '^https?://(?:www\\.)?github\\.com/([A-Za-z0-9-]+)/?' \
                "$author_url"
            )

            set --local direct_owners

            if string match -rq '^[A-Za-z0-9-]+$' "$author"
              set --append direct_owners "$author"
            end

            if string match -rq '^[A-Za-z0-9-]+$' "$author_url_owner"; and \
                not contains -- "$author_url_owner" $direct_owners
              set --append direct_owners "$author_url_owner"
            end

            set --local normalized_id (
              string lower "$library_id" |
              string replace -ra '[^a-z0-9]' '''
            )

            if test (string length "$normalized_id") -lt 3
              set --append missing_entries \
                "$entry_name — manifest id is too short"
              continue
            end

            # Resolve the manifest's declared repository path first: author/id,
            # then the GitHub owner in authorUrl/id. A remote manifest must have
            # the same id and author before its URL can be saved.
            for direct_owner in $direct_owners
              if not string match -rq '^[A-Za-z0-9._-]+$' "$library_id"
                continue
              end

              set --local direct_candidate "$direct_owner/$library_id"
              set --local direct_release_manifest_url (
                __obsidian_missing_release_asset_url \
                  "$direct_candidate" manifest.json
              )
              set --local direct_manifest_matches

              if test -n "$direct_release_manifest_url"
                set direct_manifest_matches (
                  command curl --fail --location --silent --show-error \
                    "$direct_release_manifest_url" |
                  command jq -e \
                    --arg id "$library_id" \
                    --arg author "$author" \
                    '
                      if type == "object" then
                        (.id | type) == "string" and .id == $id and
                        (if $author == "" then true else
                          (.author? | type) == "string" and .author == $author
                        end)
                      else
                        false
                      end
                    ' \
                    >/dev/null
                )
              else
                set direct_manifest_matches (
                  command gh api \
                    "repos/$direct_candidate/contents/manifest.json" \
                    --jq .content \
                    2>/dev/null |
                  command tr -d '\n' |
                  command base64 -D \
                    2>/dev/null |
                  command jq -e \
                    --arg id "$library_id" \
                    --arg author "$author" \
                    '
                      if type == "object" then
                        (.id | type) == "string" and .id == $id and
                        (if $author == "" then true else
                          (.author? | type) == "string" and .author == $author
                        end)
                      else
                        false
                      end
                    ' \
                    >/dev/null
                )
              end

              if test $status -eq 0
                set --local direct_repository_url "https://github.com/$direct_candidate"

                if not __obsidian_missing_save_repository_url \
                    "$manifest_file" \
                    "$manifest_url_field" \
                    "$direct_repository_url"
                  set --append missing_entries \
                    "$entry_name — could not save verified repository URL"
                  continue
                end

                echo "Saved $manifest_url_field in $manifest_file"

                __obsidian_missing_restore_standard_files \
                  "$library_entry" \
                  "$direct_repository_url" \
                  "$requires_plugin_payload"

                continue
              end
            end

            # Search repository manifests by the installed ID, rather than
            # presenting arbitrary repositories whose names happen to be similar.
            # Keep a failed GitHub response out of the candidate list entirely.
            set --local candidates
            set --local manifest_search_query \
              "\"$library_id\" filename:manifest.json"
            set --local manifest_candidates (
              command gh api \
                --method GET \
                search/code \
                -f "q=$manifest_search_query" \
                -f per_page=100 \
                --jq '.items[]? | .repository.full_name' \
                2>/dev/null
            )

            if test $status -eq 0
              set candidates $manifest_candidates
            end

            # Release-only manifests are not indexed by GitHub code search.
            # Also inspect the declared author's repositories so a release can
            # establish identity before falling back to repository contents.
            set --local fallback_owner "$author"

            if not string match -rq '^[A-Za-z0-9-]+$' "$fallback_owner"
              set fallback_owner "$author_url_owner"
            end

            if not string match -rq '^[A-Za-z0-9-]+$' "$fallback_owner"
              set fallback_owner
            end

            if test -n "$fallback_owner"
              set --local owner_candidates (
                command gh api \
                  "users/$fallback_owner/repos?per_page=100&type=owner" \
                  --jq '.[] | select(.archived | not) | .full_name' \
                  2>/dev/null
              )

              if test $status -eq 0
                for owner_candidate in $owner_candidates
                  if not contains -- "$owner_candidate" $candidates
                    set --append candidates "$owner_candidate"
                  end
                end
              end
            end

            if test (count $candidates) -eq 0
              set --append missing_entries \
                "$entry_name — no matching GitHub repository found"
              continue
            end

            set --local id_candidates
            set --local candidate_details

            for candidate in $candidates
              set --local candidate_release_manifest_url (
                __obsidian_missing_release_asset_url "$candidate" manifest.json
              )
              set --local candidate_manifest_fields

              if test -n "$candidate_release_manifest_url"
                set candidate_manifest_fields (
                  command curl --fail --location --silent --show-error \
                    "$candidate_release_manifest_url" |
                  command jq -r \
                    'if type == "object" then
                      if (.id | type) == "string" then
                        [.id, (.author // ""), (.authorUrl // "")] | @tsv
                      else
                        empty
                      end
                    else
                      empty
                    end'
                )
              else
                set candidate_manifest_fields (
                  command gh api \
                    "repos/$candidate/contents/manifest.json" \
                    --jq .content \
                    2>/dev/null |
                  command tr -d '\n' |
                  command base64 -D \
                    2>/dev/null |
                  command jq -r \
                    'if type == "object" then
                      if (.id | type) == "string" then
                        [.id, (.author // ""), (.authorUrl // "")] | @tsv
                      else
                        empty
                      end
                    else
                      empty
                    end'
                )
              end

              if test (count $candidate_manifest_fields) -ne 1
                continue
              end

              set --local candidate_fields (
                string split \t "$candidate_manifest_fields[1]"
              )
              set --local candidate_id "$candidate_fields[1]"
              set --local candidate_author "$candidate_fields[2]"
              set --local candidate_author_url "$candidate_fields[3]"

              if test "$candidate_id" != "$library_id"
                continue
              end

              if test "$candidate_author" != "$author"
                continue
              end

              # A plugin candidate must provide a usable compiled payload, either
              # at its root or in its newest release. Do not offer source-only
              # repositories that happen to contain a matching manifest.
              if test "$requires_plugin_payload" -eq 1
                set --local candidate_main_url (
                  __obsidian_missing_release_asset_url "$candidate" main.js
                )

                if test -z "$candidate_main_url"
                  set candidate_main_url (
                  command gh api \
                    "repos/$candidate/contents/main.js" \
                    --jq .download_url \
                    2>/dev/null
                  )
                end

                if test -z "$candidate_main_url"
                  continue
                end
              end

              set --append id_candidates "$candidate"
              set --append candidate_details (
                string join \t \
                  "$candidate" \
                  "$candidate_author" \
                  "$candidate_author_url"
              )

            end

            if test (count $id_candidates) -eq 0
              set --append missing_entries \
                "$entry_name — no remote manifest with matching id and author"
              continue
            end

            if test (count $id_candidates) -eq 1
              set --local selected_url "https://github.com/$id_candidates[1]"
            else
              set --local candidate_urls
              set --local candidate_index 1

              echo "Choose a repository for $entry_name:"
              echo "  local id: $library_id"
              echo "  local author: $author"

              for candidate_detail in $candidate_details
                set --local candidate_parts (
                  string split \t "$candidate_detail"
                )
                set --local candidate "$candidate_parts[1]"
                set --local candidate_author "$candidate_parts[2]"
                set --local candidate_author_url "$candidate_parts[3]"

                set --append candidate_urls "$candidate"
                echo "  $candidate_index) $candidate"
                echo "     author: $candidate_author"
                if test -n "$candidate_author_url"
                  echo "     authorUrl: $candidate_author_url"
                end
                echo "     https://github.com/$candidate"

                set candidate_index (
                  math "$candidate_index + 1"
                )
              end

              read --prompt-str "Choose a repository number, or s to skip: " selection

              if test "$selection" = s; or test "$selection" = S
                set --append missing_entries \
                  "$entry_name — skipped by user"
                continue
              end

              if not string match -rq '^[0-9]+$' "$selection"; or \
                test "$selection" -lt 1; or \
                test "$selection" -gt (count $candidate_urls)
                set --append missing_entries \
                  "$entry_name — invalid repository selection"
                continue
              end

              set --local selected_url \
                "https://github.com/$candidate_urls[$selection]"
            end

            if not __obsidian_missing_save_repository_url \
                "$manifest_file" \
                "$manifest_url_field" \
                "$selected_url"
              set --append missing_entries \
                "$entry_name — could not save verified repository URL"
              continue
            end

            echo "Saved $manifest_url_field in $manifest_file"

            __obsidian_missing_restore_standard_files \
              "$library_entry" \
              "$selected_url" \
              "$requires_plugin_payload"
          end

          set --local unresolved_repository_entries
          for library_entry in "$library_root"/*
            if not test -d "$library_entry"
              continue
            end
            set --local manifest_file "$library_entry/manifest.json"
            if not test -f "$manifest_file"
              set manifest_file "$library_entry/repo/manifest.json"
            end
            if not test -f "$manifest_file"
              set --append unresolved_repository_entries (basename "$library_entry")
              continue
            end
            set --local entry_abandoned (
              command jq -r \
                'if type == "object" and .abandoned == "yes" then "yes" else empty end' \
                "$manifest_file" \
                2>/dev/null
            )
            if test "$entry_abandoned" = yes
              continue
            end
            set --local manifest_repository_url (
              command jq -r \
                --arg field "$manifest_url_field" \
                'if (.[$field] | type) == "string" then .[$field] else empty end' \
                "$manifest_file" |
              string match -r -m 1 '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?'
            )
            if test -z "$manifest_repository_url"
              set --append unresolved_repository_entries (basename "$library_entry")
            end
          end

          if test (count $unresolved_repository_entries) -gt 0
            printf '%s\n' $unresolved_repository_entries >"$missing_report"
            echo "Folders that still need a usable manifest repository URL:"
            echo "  $missing_report"
          else
            printf '%s\n' "All scanned entries have a usable manifest repository URL." >"$missing_report"
            echo "All scanned entries have a usable manifest repository URL."
          end
        '';
      };
      # -----------------------------------------------------------------
    };
  };
}
