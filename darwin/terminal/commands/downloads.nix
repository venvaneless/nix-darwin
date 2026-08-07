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
  # ---- gitdll -> Download Git repositories or rebuild Obsidian libraries ---- #
  #
  # Existing repository download modes:
  # gitdll "https://github.com/owner/repository"
  # gitdll "https://github.com/owner/one" "https://github.com/owner/two"
  # gitdll links.txt
  #
  # Obsidian download modes:
  # gitdll --plugins "https://github.com/owner/plugin" [...]
  # gitdll --themes links.txt [...]
  #
  # In the Obsidian modes, source directories are checked one level deep.
  # A saved repository-url.txt is reused immediately. When it is absent,
  # gitdll resolves only the matching repository metadata and saves the URL
  # before handing the actual files to the downloader functions.
  # -----------------------------------------------------------------
  gitdll = {
    description = "Download Git repositories, Obsidian plugins, or Obsidian themes";

    body = ''
      if test (count $argv) -gt 0; and \
          contains -- "$argv[1]" --plugins --themes

        set --local mode "$argv[1]"
        set --local source_inputs
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
          echo '  gitdll --plugins "https://github.com/owner/plugin" [...]'
          echo '  gitdll --themes links.txt [...]'
          return 1
        end

        for source_input in $source_inputs
          if not test -d "$source_input"; and not test -f "$source_input"; and \
              not string match -rq '(?i)^(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?/?$' "$source_input"
            echo "Error: Repository URL, source directory, or link file does not exist:"
            echo "  $source_input"
            return 1
          end
        end

        # Keep selected downloader settings outside the mode conditional.
        set --local library_type
        set --local downloader_function
        set --local missing_report_name
        set --local failed_report_name

        if test "$mode" = "--plugins"
          if not functions -q __gitdll_plugins
            echo "Error: the plugin downloader is not available."
            return 1
          end

          set library_type plugins
          set downloader_function __gitdll_plugins
          set missing_report_name \
            missing-plugin-repository-urls.txt
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
          set missing_report_name \
            missing-theme-repository-urls.txt
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

        set --local function_file \
          "$temporary_directory/downloader.fish"

        # Keep one easy-to-find report of unavailable library entries.
        set --local undownloaded_file \
          "$temporary_directory/undownloaded.txt"

        set --local undownloaded_report \
          "$HOME/Downloads/gitdll-missing.txt"

        set --local downloader_temporary_directory \
          "$destination/.gitdll-tmp"

        command mkdir -p -- "$downloader_temporary_directory"

        command touch \
          "$repositories_file" \
          "$source_map_file" \
          "$missing_file" \
          "$failed_file"

        functions "$downloader_function" \
          >"$function_file"

        if not test -s "$function_file"
          echo "Error: Could not export $downloader_function."
          command rm -rf -- "$temporary_directory"
          return 1
        end

        function __gitdll_write_undownloaded_report \
            --no-scope-shadowing

          set --local staged_report \
            "$temporary_directory/undownloaded-report.txt"

          if test "$mode" = "--plugins"
            begin
              echo "## Plugins"

              if test -s "$undownloaded_file"
                command cat "$undownloaded_file"
              else
                echo "None"
              end

              echo

              if test -f "$undownloaded_report"
                command awk '
                  $0 == "## Themes" { printing = 1 }
                  /^## / && $0 != "## Themes" { printing = 0 }
                  printing { print }
                ' "$undownloaded_report"
              else
                echo "## Themes"
                echo "None"
              end
            end >"$staged_report"
          else
            begin
              if test -f "$undownloaded_report"
                command awk '
                  $0 == "## Plugins" { printing = 1 }
                  /^## / && $0 != "## Plugins" { printing = 0 }
                  printing { print }
                ' "$undownloaded_report"
              else
                echo "## Plugins"
                echo "None"
              end

              echo
              echo "## Themes"

              if test -s "$undownloaded_file"
                command cat "$undownloaded_file"
              else
                echo "None"
              end
            end >"$staged_report"
          end

          if not command mv -- "$staged_report" "$undownloaded_report"
            echo "Error: Could not update unavailable library report:"
            echo "  $undownloaded_report"
            return 1
          end
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
          echo "Scanning source:"
          echo "  $source_input"

          if string match -rq '(?i)^(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?/?$' "$source_input"
            set --local repository_url (
              string match -r -m 1 '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' "$source_input"
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

                printf '%s\\t%s\\n' \
                  "$source_name" \
                  "$repository_url" \
                  >>"$missing_file"

                set missing_count (
                  math "$missing_count + 1"
                )

                continue
              end

              printf '%s\\n' \
                "$repository_url" \
                >>"$repositories_file"

              printf '%s\\t%s\\n' \
                "$source_name" \
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

            if test -n "$repository_url"
              # Cache only a verified match. The next run then requires no
              # GitHub lookup and no interactive choice.
              printf '%s\n' "$repository_url" \
                >"$source_folder/repository-url.txt" 2>/dev/null
            end
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

        set --local missing_report \
          "$destination/$missing_report_name"

        if test -s "$missing_file"
          command cp -f \
            "$missing_file" \
            "$missing_report"
        else
          command rm -f -- "$missing_report"
        end

        echo
        echo "============================================================"
        echo "OBSIDIAN "(string upper "$library_type")
        echo "============================================================"
        echo "Sources:"
        for source_input in $source_inputs
          echo "  $source_input"
        end
        echo
        echo "Destination:"
        echo "  $destination"
        echo
        echo "Source entries:          $source_count"
        echo "Usable repository URLs: $repository_count"
        echo "Missing or invalid URLs: $missing_count"
        echo "============================================================"

        if test "$missing_count" -gt 0
          echo
          echo "Folders without a usable repository-url.txt:"
          echo

          while read --local missing_entry
            if test -n "$missing_entry"
              echo "  $missing_entry"
            end
          end <"$missing_file"

          echo
          echo "Missing URL report:"
          echo "  $missing_report"
        end

        if test "$repository_count" -eq 0
          command sort -u "$missing_file" >"$undownloaded_file"

          __gitdll_write_undownloaded_report
          set --local report_status $status

          functions -e __gitdll_write_undownloaded_report
          echo
          echo "Error: No usable repository URLs were found."
          command rm -rf -- "$temporary_directory"

          if test "$report_status" -ne 0
            return "$report_status"
          end

          return 1
        end

        echo
        echo "Downloading fresh copies..."
        echo

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
          "$destination"

        set --local downloader_status $status

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

          set --local matching_repository_file (
            command find "$destination" \
              -mindepth 2 \
              -maxdepth 2 \
              -type f \
              -name repository-url.txt \
              -exec grep \
                -lFx \
                "$original_url" \
                {} \; \
              2>/dev/null |
            command head -n 1
          )

          if test -z "$matching_repository_file"
            printf '%s — download failed: %s\n' \
              "$original_name" \
              "$original_url" \
              >>"$failed_file"
          else
            set downloaded_count (
              math "$downloaded_count + 1"
            )
          end
        end <"$source_map_file"

        set --local failed_report \
          "$destination/$failed_report_name"

        if test -s "$failed_file"
          command cp -f \
            "$failed_file" \
            "$failed_report"
        else
          command rm -f -- "$failed_report"
        end

        set --local failed_count (
          command wc -l \
            <"$failed_file" |
          string trim
        )

        command cat "$missing_file" "$failed_file" |
          command sort -u \
          >"$undownloaded_file"

        __gitdll_write_undownloaded_report
        set --local report_status $status

        echo
        echo "============================================================"
        echo "DOWNLOAD SUMMARY"
        echo "============================================================"
        echo "Available at destination: $downloaded_count"
        echo "Missing repository URL:  $missing_count"
        echo "Failed downloads:        $failed_count"
        echo "============================================================"

        if test "$failed_count" -gt 0
          echo
          echo "Repositories that were not downloaded:"
          echo

          while read --local failed_entry
            if test -n "$failed_entry"
              echo "  $failed_entry"
            end
          end <"$failed_file"

          echo
          echo "Failed download report:"
          echo "  $failed_report"
        end

        command rm -rf -- "$temporary_directory"

        functions -e __gitdll_write_undownloaded_report

        if test "$report_status" -ne 0
          return "$report_status"
        end

        if test "$downloader_status" -ne 0
          return "$downloader_status"
        end

        if test "$failed_count" -gt 0
          return 1
        end

        return 0
      end

      set --local destination "$HOME/Downloads/gitdll"

      if test (count $argv) -eq 0
        echo "Usage:"
        echo '  gitdll "https://github.com/owner/repository" [...]'
        echo "  gitdll <links.txt> [more-links-or-files ...]"
        echo
        echo "Obsidian library modes:"
        echo '  gitdll --plugins "https://github.com/owner/plugin" [...]'
        echo '  gitdll --themes links.txt [...]'
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

      if not command -q jq
          echo "Error: jq is not installed."
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

          # Fetch only files needed to rebuild the plugin, never an archive.
          set repository_paths (
              command gh api \
                  "repos/$repository_owner/$repository_name/git/trees/HEAD?recursive=1" \
                  --jq \
                  '.tree[]? | select(.type == "blob" and (.path | test("(^|/)node_modules/") | not)) | .path' \
                  2>/dev/null
          )

          # Prefer standard files from the newest release before repository fallback.
          set release_json (
              command gh api \
                  "repos/$repository_owner/$repository_name/releases/latest" \
                  2>/dev/null
          )

          if test $status -eq 0; and test -n "$release_json"
              set release_assets (
                  printf "%s" "$release_json" |
                  command jq -r \
                      '.assets[]? | [.name, .browser_download_url] | @tsv'
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
          for readme_name in README README.md README.markdown README.txt
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
              echo "Error: manifest.json was not found."
              command rm -rf -- "$temporary_directory"
              continue
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

          if test -z "$plugin_id"
              echo "Error: manifest.json does not contain a valid plugin id."
              command rm -rf -- "$temporary_directory"
              continue
          end

          if string match -rq '[/\x00]' "$plugin_id"
              echo "Error: Plugin id contains unsafe folder-name characters."
              command rm -rf -- "$temporary_directory"
              continue
          end

          if test "$plugin_id" = "."
              echo "Error: Plugin id is unsafe."
              command rm -rf -- "$temporary_directory"
              continue
          end

          if test "$plugin_id" = ".."
              echo "Error: Plugin id is unsafe."
              command rm -rf -- "$temporary_directory"
              continue
          end

          set plugin_directory "$destination/$plugin_id"
          set plugin_directory_exists 0
          set refresh_plugin_manifest 0

          if test -d "$plugin_directory"
              set plugin_manifest_indented 0
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

              if test -r "$plugin_directory/manifest.json"; and \
                      test -s "$plugin_directory/manifest.json"; and \
                      command jq -e . "$plugin_directory/manifest.json" >/dev/null 2>&1; and \
                      command jq --indent 2 . "$plugin_directory/manifest.json" | \
                          command cmp -s - "$plugin_directory/manifest.json"
                  set plugin_manifest_indented 1
              end

              if test -r "$plugin_directory/manifest.json"; and \
                      test -s "$plugin_directory/manifest.json"; and \
                      command jq -e . \
                          "$plugin_directory/manifest.json" \
                          >/dev/null 2>&1; and \
                      test "$plugin_manifest_indented" -eq 1; and \
                      test -r "$plugin_directory/main.js"; and \
                      test -s "$plugin_directory/main.js"; and \
                      test -f "$plugin_directory/repository-url.txt"; and \
                      test "$plugin_readme_ok" -eq 1

                  echo
                  echo "Skipping:"
                  echo "  $plugin_id (already complete)"
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              if test -r "$plugin_directory/manifest.json"; and \
                      test -s "$plugin_directory/manifest.json"; and \
                      command jq -e . "$plugin_directory/manifest.json" >/dev/null 2>&1; and \
                      test "$plugin_manifest_indented" -eq 0; and \
                      test -r "$plugin_directory/main.js"; and \
                      test -s "$plugin_directory/main.js"; and \
                      test -f "$plugin_directory/repository-url.txt"
                  echo
                  echo "Plugin manifest.json is not canonically indented:"
                  echo "  $plugin_id"
                  read --local --prompt-str="Re-download this plugin now? [y/N] " confirmation
                  if not string match -irq '^y(es)?$' -- "$confirmation"
                      echo "Skipping unchanged plugin: $plugin_id"
                      command rm -rf -- "$temporary_directory"
                      continue
                  end
                  set refresh_plugin_manifest 1
              end

              echo
              echo "Resuming incomplete plugin:"
              echo "  $plugin_id"
              set plugin_directory_exists 1
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
              command cp -f \
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
                      '.assets[]? | [.name, .browser_download_url] | @tsv'
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

                          if command curl \
                                  --fail \
                                  --location \
                                  --silent \
                                  --show-error \
                                  --output "$plugin_stage/$release_asset_name" \
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
                          # GitHub's source archives are not listed in .assets.
                          command mkdir -p \
                              "$plugin_stage/release-assets"

                          if test -f \
                                  "$plugin_stage/release-assets/$release_asset_name"
                              continue
                          end

                          if command curl \
                                  --fail \
                                  --location \
                                  --silent \
                                  --show-error \
                                  --output "$plugin_stage/release-assets/$release_asset_name" \
                                  "$release_asset_url"

                              set saved_files \
                                  $saved_files \
                                  "release-assets/$release_asset_name"
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
                  command cp -f \
                      "$repository_file" \
                      "$plugin_stage/$expected_file"

                  if not contains "$expected_file" $saved_files
                      set saved_files \
                          $saved_files \
                          "$expected_file"
                  end
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

              if not test -s "$plugin_stage/$readme_output"; or \
                      test "$refresh_plugin_manifest" -eq 1
                  command cp -f \
                      "$readme" \
                      "$plugin_stage/$readme_output"
              end

              set saved_files \
                  $saved_files \
                  "$readme_output"
          else
              echo "Notice: No README file was found."
          end

          printf '%s\n' \
              "$canonical_repository_url" \
              >"$plugin_stage/repository-url.txt"

          set saved_files \
              $saved_files \
              repository-url.txt

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

          set fallback_folder_name (
              string lower "$repository_name" |
              string replace -ra \
                  '(?i)(?:-?(?:master|repo|dotfiles|main))+$' \
                  ''' |
              string replace -ra '[ _]+' '-' |
              string replace -ra '[^a-z0-9._-]' '-' |
              string replace -ra -- '-+' '-' |
              string trim --chars=- |
              string trim
          )

          if test -z "$fallback_folder_name"
              set fallback_folder_name theme
          end

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

              if test -r "$existing_theme_directory/theme.css"; and \
                      test -s "$existing_theme_directory/theme.css"; and \
                      test "$existing_theme_manifest_ok" -eq 1; and \
                      test "$existing_theme_readme_ok" -eq 1
                  echo
                  echo "Skipping:"
                  echo "  $existing_theme_directory (already complete)"
                  continue
              end
          end

          echo
          echo "Repository:"
          echo "  $canonical_repository_url"

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

          # Fetch only theme files, never an entire repository archive.
          set repository_paths (
              command gh api \
                  "repos/$repository_owner/$repository_name/git/trees/HEAD?recursive=1" \
                  --jq \
                  '.tree[]? | select(.type == "blob" and (.path | test("(^|/)node_modules/") | not)) | .path' \
                  2>/dev/null
          )

          # Prefer standard files from the newest release before repository fallback.
          set release_json (
              command gh api \
                  "repos/$repository_owner/$repository_name/releases/latest" \
                  2>/dev/null
          )

          if test $status -eq 0; and test -n "$release_json"
              set release_assets (
                  printf "%s" "$release_json" |
                  command jq -r \
                      '.assets[]? | [.name, .browser_download_url] | @tsv'
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
                      case manifest.json theme.css obsidian.css
                          command curl \
                              --fail \
                              --location \
                              --silent \
                              --show-error \
                              --output "$extracted/$release_asset_name" \
                              "$release_asset_url"
                  end
              end
          end

          for expected_file in manifest.json theme.css obsidian.css
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
          for readme_name in README README.md README.markdown README.txt
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
                      '.assets[]? | [.name, .browser_download_url] | @tsv'
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
                      case manifest.json theme.css obsidian.css
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
                          # GitHub's source archives are not listed in .assets.
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
          set theme_id

          if test -n "$manifest"
              set manifest_directory (dirname "$manifest")

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

          set theme_folder_name "$theme_id"

          if test -z "$theme_folder_name"
              set theme_folder_name "$fallback_folder_name"
          end

          if string match -rq '[/\x00]' "$theme_folder_name"
              echo "Error: Theme id contains unsafe folder-name characters."
              command rm -rf -- "$temporary_directory"
              continue
          end

          if test "$theme_folder_name" = "."
              echo "Error: Theme id contains an unsafe folder name."
              command rm -rf -- "$temporary_directory"
              continue
          end

          if test "$theme_folder_name" = ".."
              echo "Error: Theme id contains an unsafe folder name."
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

              if test -r "$theme_directory/theme.css"; and \
                      test -s "$theme_directory/theme.css"; and \
                      test "$theme_manifest_ok" -eq 1; and \
                      test -f "$theme_directory/repository-url.txt"; and \
                      test "$theme_readme_ok" -eq 1

                  echo
                  echo "Skipping:"
                  echo "  $theme_folder_name (already complete)"
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              echo
              echo "Resuming incomplete theme:"
              echo "  $theme_folder_name"
              set theme_directory_exists 1
          end

          set theme_stage "$temporary_directory/theme"

          if test "$theme_directory_exists" -eq 1
              set theme_stage "$theme_directory"
          else
              command mkdir -p -- "$theme_stage"
          end

          set saved_files

          if test -d "$extracted/release-assets"
              command mkdir -p "$theme_stage/release-assets"

              for release_asset in "$extracted/release-assets"/*
                  set release_asset_name (basename "$release_asset")

                  if test -e "$theme_stage/release-assets/$release_asset_name"
                      continue
                  end

                  command cp -R \
                      "$release_asset" \
                      "$theme_stage/release-assets/$release_asset_name"

                  set saved_files release-assets
              end
          end

          if test -n "$manifest"; and test -f "$manifest"
              if not test -r "$theme_stage/manifest.json"; or \
                      not test -s "$theme_stage/manifest.json"; or \
                      not command jq -e . \
                          "$theme_stage/manifest.json" \
                          >/dev/null 2>&1
                  command cp -f \
                      "$manifest" \
                      "$theme_stage/manifest.json"
              end

              set saved_files manifest.json
          end

          if test -f "$source_theme_css"
              if not test -r "$theme_stage/theme.css"; or \
                      not test -s "$theme_stage/theme.css"
                  command cp -f \
                      "$source_theme_css" \
                      "$theme_stage/theme.css"
              end

              set saved_files $saved_files theme.css
          else
              if not test -r "$theme_stage/theme.css"; or \
                      not test -s "$theme_stage/theme.css"
                  command cp -f \
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

          # Save named theme preview images without downloading an archive.
          set preview_count 0

          for repository_image_path in $repository_paths
              set repository_image_name (
                  basename "$repository_image_path"
              )

              if not string match -rq \
                      '(?i)(screenshot|screen|screencap|preview|previews|[-_]dark|[-_]light).+\.(png|jpe?g|gif|webp|svg)$' \
                      "$repository_image_name"

                  continue
              end

              set repository_image_url (
                  command gh api \
                      "repos/$repository_owner/$repository_name/contents/$repository_image_path" \
                      --jq .download_url \
                      2>/dev/null
              )

              if test -z "$repository_image_url"
                  continue
              end

              set preview_count (
                  math "$preview_count + 1"
              )

              set preview_name (
                  string replace -ra \
                      '[^A-Za-z0-9._-]' \
                      '_' \
                      "$repository_image_name"
              )

              command mkdir -p "$theme_stage/previews"

              if test -f "$theme_stage/previews/$preview_count-$preview_name"
                  continue
              end

              if command curl \
                      --fail \
                      --location \
                      --silent \
                      --show-error \
                      --output "$theme_stage/previews/$preview_count-$preview_name" \
                      "$repository_image_url"

                  set saved_files \
                      $saved_files \
                      "previews/$preview_count-$preview_name"
              else
                  echo \
                      "Notice: Could not download theme preview image: $repository_image_name"
              end
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

              if not test -s "$theme_stage/$readme_output"
                  command cp -f \
                      "$readme" \
                      "$theme_stage/$readme_output"
              end

              set saved_files \
                  $saved_files \
                  "$readme_output"

              set readme_directory (dirname "$readme")
              set readme_contents (command cat "$readme")

              set image_references (
                  string match -ra \
                      --groups-only \
                      '!\[[^]]*\]\(\s*<?([^ >)]+)' \
                      $readme_contents
              )

              set image_references \
                  $image_references \
                  (
                      string match -ria \
                          --groups-only \
                          "<img[^>]+src=[\"']([^\"']+)" \
                          $readme_contents
                  )

              set seen_images
              set preview_count 0

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

                      set download_url \
                          "$image_reference"

                      if string match -rq \
                              '^https://github\.com/' \
                              "$download_url"

                          set download_url (
                              string replace -r \
                                  '^https://github\.com/' \
                                  'https://raw.githubusercontent.com/' \
                                  "$download_url"
                          )

                          set download_url (
                              string replace \
                                  '/blob/' \
                                  '/' \
                                  "$download_url"
                          )
                      end

                      set remote_filename (
                          basename (
                              string replace -r \
                                  '[?#].*$' \
                                  ''' \
                                  "$download_url"
                          )
                      )

                      if test -z "$remote_filename"; or \
                              test "$remote_filename" = "/"

                          set remote_filename preview
                      end

                      set remote_filename (
                          string replace -ra \
                              '[^A-Za-z0-9._-]' \
                              '_' \
                              "$remote_filename"
                      )

                      set preview_count (
                          math "$preview_count + 1"
                      )

                      set preview_destination \
                          "$theme_stage/previews/$preview_count-$remote_filename"

                      command mkdir -p \
                          "$theme_stage/previews"

                      if test -f "$preview_destination"
                          continue
                      end

                      if command curl \
                              --fail \
                              --location \
                              --silent \
                              --show-error \
                              --output "$preview_destination" \
                              "$download_url"

                          set saved_files \
                              $saved_files \
                              "previews/$preview_count-$remote_filename"
                      else
                          command rm -f \
                              -- \
                              "$preview_destination"

                          echo \
                              "Notice: Could not download README preview image: $image_reference"
                      end
                  else if not string match -rq \
                          '(^|/)\.\.(/|$)' \
                          "$image_path"; and \
                          not string match -rq \
                          '^/' \
                          "$image_path"

                      set local_image \
                          "$readme_directory/$image_path"

                      if test -f "$local_image"
                          set local_parent \
                              (dirname "$image_path")

                          command mkdir -p \
                              "$theme_stage/$local_parent"

                          if not test -f "$theme_stage/$image_path"
                              command cp -f \
                                  "$local_image" \
                                  "$theme_stage/$image_path"
                          end

                          set saved_files \
                              $saved_files \
                              "$image_path"
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

          printf '%s\n' \
              "$canonical_repository_url" \
              >"$theme_stage/repository-url.txt"

          set saved_files \
              $saved_files \
              repository-url.txt

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
  # ---- obsidian-missing -> Restore repository URL files ---- #
  # -----------------------------------------------------------------
  obsidian-missing = {
    description = "Interactively restore missing Obsidian repository-url.txt files";

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

      if not command -q base64
        echo "Error: base64 is not installed."
        return 1
      end

      # Write only a verified, non-empty GitHub URL. A temporary sibling file
      # prevents a failed lookup from truncating an existing repository file.
      function __obsidian_missing_save_repository_url \
          --argument-names repository_file repository_url

        if not string match -rq '^https://github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$repository_url"
          return 1
        end

        if test -L "$repository_file"
          echo "Error: Refusing to replace symlinked repository-url.txt: $repository_file"
          return 1
        end

        set --local staging_file "$repository_file.obsidian-missing-new"

        if not printf '%s\n' "$repository_url" >"$staging_file"
          command rm -f -- "$staging_file"
          return 1
        end

        if not command mv -- "$staging_file" "$repository_file"
          command rm -f -- "$staging_file"
          return 1
        end
      end

      # Keep an existing non-empty README untouched. When no usable README is
      # present, restore README.md from the verified GitHub repository.
      function __obsidian_missing_restore_readme \
          --argument-names library_entry repository_url

        if command find "$library_entry" \
            -maxdepth 1 \
            -type f \
            \( -iname 'README' -o -iname 'README.md' -o -iname 'README.markdown' -o -iname 'README.txt' \) \
            -size +0c \
            -print \
            -quit | read --local existing_readme
          return 0
        end

        set --local repository (
          string replace -r '^(?:https?://)?(?:www\\.)?github\\.com/' "" -- "$repository_url" |
          string replace -r '\\.git$' ""
        )
        if not string match -rq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' "$repository"
          echo "Notice: Could not restore README.md for $library_entry; repository URL is invalid."
          return 1
        end
        if test -L "$library_entry/README.md"
          echo "Error: Refusing to replace symlinked README.md: $library_entry/README.md"
          return 1
        end
        set --local staging_readme "$library_entry/README.md.obsidian-missing-new"

        if not command gh api "repos/$repository/readme" --jq .content 2>/dev/null | \
            command base64 -D >"$staging_readme"
          command rm -f -- "$staging_readme"
          echo "Notice: Could not restore README.md for $library_entry"
          return 1
        end

        if not test -s "$staging_readme"; or \
            not command mv -- "$staging_readme" "$library_entry/README.md"
          command rm -f -- "$staging_readme"
          echo "Notice: Could not save README.md for $library_entry"
          return 1
        end

        echo "Saved $library_entry/README.md"
      end

      set --local missing_entries
      set --local missing_repository_entries
      set --local missing_report "$HOME/Downloads/obsidian-missing.txt"
      set --local library_root_name (
        basename "$library_root" | string lower
      )
      set --local requires_plugin_payload 0

      if string match -rq '(plugin|extension)' "$library_root_name"
        set requires_plugin_payload 1
      end

      # List every manifest-backed entry before looking for a repository URL.
      # Repository metadata is needed only for recovery and downloads.
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
          set --append missing_entries \
            "$entry_name — manifest.json missing"
          continue
        end

        set --local manifest_fields (
          command jq -r \
            'if type == "object" then
              [(.id // ""), (.author // ""), (.description // ""), (.version // "")]
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
        set --local table_id "$entry_name"
        set --local table_author "-"
        set --local table_description "-"
        set --local table_version "-"

        if test (count $manifest_columns) -eq 4
          if test -n "$manifest_columns[1]"
            set table_id "$manifest_columns[1]"
          end
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
        if test -z "$table_author"
          set table_author "-"
        end
        if test -z "$table_description"
          set table_description "-"
        end
        if test -z "$table_version"
          set table_version "-"
        end
        printf '%-28s %-20s %-56s %s\n' \
          "$table_id" \
          "$table_author" \
          "$table_description" \
          "$table_version"

        set --local repository_file \
          "$library_entry/repository-url.txt"

        set --local existing_repository_url
        for repository_candidate in \
            "$library_entry/repository-url.txt" \
            "$library_entry/repo/repository-url.txt"
          if not test -f "$repository_candidate"; or \
              not test -s "$repository_candidate"
            continue
          end

          set existing_repository_url (
            string match -r -m 1 '(?i)(?:https?://)?(?:www\\.)?github\\.com/[A-Za-z0-9-]+/[A-Za-z0-9._-]+(?:\\.git)?' <"$repository_candidate"
          )
          if test -n "$existing_repository_url"
            set repository_file "$repository_candidate"
            break
          end
        end

        if test -n "$existing_repository_url"
          echo "Keeping existing repository URL: $repository_file"
          __obsidian_missing_restore_readme \
            "$library_entry" \
            "$existing_repository_url"
          continue
        end

        set --append missing_repository_entries "$entry_name"

        if not test -f "$repository_file"; and \
            test -f "$library_entry/repo/repository-url.txt"
          set repository_file "$library_entry/repo/repository-url.txt"
        end

        if test -f "$repository_file"; and test -s "$repository_file"
          set --append missing_entries \
            "$entry_name — repository-url.txt is non-empty but has no GitHub URL; preserved"
          continue
        end

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
                "$repository_file" \
                "$direct_repository_url"
              set --append missing_entries \
                "$entry_name — could not save verified repository URL"
              continue
            end

            echo "Saved $repository_file"
            __obsidian_missing_restore_readme "$library_entry" "$direct_repository_url"
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
            "$repository_file" \
            "$selected_url"
          set --append missing_entries \
            "$entry_name — could not save verified repository URL"
          continue
        end

        echo "Saved $repository_file"
        __obsidian_missing_restore_readme "$library_entry" "$selected_url"
      end

      if test (count $missing_repository_entries) -gt 0
        printf '%s\n' $missing_repository_entries >"$missing_report"
        echo "Folders that were missing a usable repository-url.txt:"
        echo "  $missing_report"
      else
        printf '%s\n' "All scanned entries have a usable repository-url.txt." >"$missing_report"
        echo "All scanned entries have a usable repository-url.txt."
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
    # ---- resolve-obsidian-repos -> Find repository URLs ---- #
    #
    # Resolves only missing or empty repository-url.txt files in the
    # permanent Obsidian plugin or theme library.
    #
    # Examples:
    # resolve-obsidian-repos plugins
    # resolve-obsidian-repos themes
    # resolve-obsidian-repos all
    # -----------------------------------------------------------------
    resolve-obsidian-repos = {
      description = "Safely restore missing Obsidian repository URLs";

      body = ''
        set --local plugins_root "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/data-backups/app-backups/obsidian/obsidian_extensions"

        set --local themes_root "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/data-backups/app-backups/obsidian/obsidian_themes"

        if test (count $argv) -gt 1; or \
            test (count $argv) -eq 1; and \
            not contains -- "$argv[1]" plugins themes all
          echo "Usage: resolve-obsidian-repos [plugins|themes|all]"
          return 1
        end

        set --local target all

        if test (count $argv) -eq 1
          set target "$argv[1]"
        end

        if not functions -q obsidian-missing
          echo "Error: obsidian-missing is not available."
          return 1
        end

        switch "$target"
          case plugins
            obsidian-missing "$plugins_root"
          case themes
            obsidian-missing "$themes_root"
          case all
            obsidian-missing "$plugins_root"
            set --local plugins_status $status
            obsidian-missing "$themes_root"
            set --local themes_status $status

            if test "$plugins_status" -ne 0
              return "$plugins_status"
            end

            return "$themes_status"
        end
      '';
    };
    # -----------------------------------------------------------------
  };
}
