# darwin/terminal/commands/downloads.nix
#
# =====================================================================
# FISH FUNCTIONS: DOWNLOADS
#
# Download helpers for:
# - Github
# - Internet Archive
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
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
        function __obsidian_missing_trash_legacy_url --argument-names legacy_file
          if not test -e "$legacy_file"; and not test -L "$legacy_file"
            return 0
          end

          set --local apple_path (
            string replace -a '\\' '\\\\' -- "$legacy_file" |
            string replace -a '"' '\\"'
          )
          if not /usr/bin/osascript \
              -e "tell application \"Finder\" to delete POSIX file \"$apple_path\""
            echo "Notice: Manifest was migrated, but legacy cleanup needs attention: $legacy_file"
            return 1
          end
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

              if __obsidian_download_name_blocked \
                  "$release_asset_name"

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
                __obsidian_download_name_blocked \
                    "$auxiliary_name"

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
            set --local direct_manifest_matches (
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
          else
            # Code search may be unavailable for a GitHub token. In that case,
            # only inspect repositories owned by the manifest author.
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
                set candidates $owner_candidates
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
            set --local candidate_manifest_fields (
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
                command gh api \
                  "repos/$candidate/contents/main.js" \
                  --jq .download_url \
                  2>/dev/null
              )

              if test $status -ne 0; or test -z "$candidate_main_url"
                set candidate_main_url (
                  command gh api \
                    "repos/$candidate/releases/latest" \
                    --jq \
                    '.assets[]? | select(.name == "main.js") | .browser_download_url' \
                    2>/dev/null |
                  command head -n 1
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
}
