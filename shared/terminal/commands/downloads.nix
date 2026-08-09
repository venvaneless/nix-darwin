# shared/terminal/commands/downloads.nix
#
# =====================================================================
# FISH FUNCTIONS: PORTABLE DOWNLOADS
#
# Portable GitHub, Obsidian-library, and Internet Archive helpers.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.fish.downloads;
in
{
  options.ven.features.terminal.fish.downloads.enable =
    lib.mkEnableOption "portable Fish download helpers";

  config = lib.mkIf cfg.enable {
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
              license \
              changelog \
              contributing \
              security \
              privacy

          # ---- BLOCKED EXACT FILE NAMES ---- #
          #
          # These specific filenames are blocked case-insensitively.
          set --local blocked_files \
              agents.md \
              claude.md \
              readme-zh_cn.md \
              readme-zh_tw.md \
              readme-zh.md \
              readme-cn.md \
              readme-tw.md

          # ---- FILE NAME ---- #
          set --local filename \
              (string lower -- (basename "$argv[1]"))

          # ---- MATCH BLOCKED BASE NAMES ---- #
          for blocked_name in $blocked_names
            if test "$filename" = "$blocked_name"; or \
                string match -q "$blocked_name.*" "$filename"

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
              __obsidian_repository_fallback_name \
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

              set --local manifest_url (
                command gh api \
                  "repos/$candidate/contents/manifest.json" \
                  --jq .download_url \
                  2>/dev/null
              )

              if test -z "$manifest_url"
                return 1
              end

              set --local payload_url

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

              test -n "$payload_url"
            end

            # Compare a remote manifest only in the fallback path. JSON parsing
            # ignores indentation and formatting; only id and author matter.
            function __gitdll_remote_matches \
                --argument-names candidate library_id library_author library_type

              set --local remote_manifest (
                command gh api \
                  "repos/$candidate/contents/manifest.json" \
                  --jq .content \
                  2>/dev/null |
                command tr -d '\n' |
                command base64 -D 2>/dev/null
              )

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
                  set repository_file_name \
                      (basename "$repository_path")

                  if string match -rq \
                          '(^|/)\.[^/]+' \
                          "$repository_path"; or \
                          string match -rq \
                          '(^|/)node_modules/' \
                          "$repository_path"; or \
                          __obsidian_download_name_blocked \
                              "$repository_file_name"

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

                      if __obsidian_download_name_blocked \
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

                  if command gh api \
                          -H "Accept: application/vnd.github.raw+json" \
                          "repos/$repository_owner/$repository_name/contents/$auxiliary_path" \
                          >"$auxiliary_destination" \
                          2>/dev/null; and \
                          test -s "$auxiliary_destination"

                      set saved_files \
                          $saved_files \
                          (string replace "$plugin_stage/" "" -- "$auxiliary_destination")
                  else
                      command rm -f \
                          "$auxiliary_destination"

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
                  set repository_file_name \
                      (basename "$repository_path")

                  if string match -rq \
                          '(^|/)\.[^/]+' \
                          "$repository_path"; or \
                          string match -rq \
                          '(^|/)node_modules/' \
                          "$repository_path"; or \
                          __obsidian_download_name_blocked \
                              "$repository_file_name"

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
    };
  };
}
