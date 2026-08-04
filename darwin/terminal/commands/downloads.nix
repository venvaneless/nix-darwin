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
  # Obsidian library rebuild modes:
  # gitdll --plugins "source path" [...] --to "destination path"
  # gitdll --themes "source path" [...] --to "destination path"
  #
  # In the Obsidian modes, source directories are checked one level deep
  # for repository-url.txt or repo/repository-url.txt. Source .txt files
  # can also provide repository links. The downloader functions remain
  # responsible for the downloads.
  # -----------------------------------------------------------------
  gitdll = {
    description = "Download Git repositories or rebuild Obsidian plugin and theme libraries";

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
          echo "Error: At least one source folder or link file is required."
          echo
          echo "Usage:"
          echo '  gitdll --plugins "source path" [...] --to "destination path"'
          echo '  gitdll --themes "source path" [...] --to "destination path"'
          return 1
        end

        if test -z "$destination"
          echo "Error: A destination folder is required with --to."
          return 1
        end

        for source_input in $source_inputs
          if not test -d "$source_input"; and not test -f "$source_input"
            echo "Error: Source directory or link file does not exist:"
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
          if not functions -q gitdll-plugins
            echo "Error: gitdll-plugins is not available."
            return 1
          end

          set library_type plugins
          set downloader_function gitdll-plugins
          set missing_report_name \
            missing-plugin-repository-urls.txt
          set failed_report_name \
            failed-plugin-downloads.txt
        else
          if not functions -q gitdll-themes
            echo "Error: gitdll-themes is not available."
            return 1
          end

          set library_type themes
          set downloader_function gitdll-themes
          set missing_report_name \
            missing-theme-repository-urls.txt
          set failed_report_name \
            failed-theme-downloads.txt
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

        for source_input in $source_inputs
          echo "Scanning source:"
          echo "  $source_input"

          if test -f "$source_input"
            set --local source_name (
              basename "$source_input"
            )

            while read --local repository_url
              set repository_url (
                string trim "$repository_url"
              )

              if test -z "$repository_url"; or \
                  string match -q '#*' "$repository_url"
                continue
              end

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

          if not test -f "$repository_file"
            printf '%s\n' \
              "$source_name" \
              >>"$missing_file"

            set missing_count (
              math "$missing_count + 1"
            )

            continue
          end

          set --local repository_url (
            command head -n 1 "$repository_file" |
            string trim
          )

          if test -z "$repository_url"
            printf '%s\n' \
              "$source_name" \
              >>"$missing_file"

            set missing_count (
              math "$missing_count + 1"
            )

            continue
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
            printf '%s\t%s\n' \
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
        echo '  gitdll --plugins "source path" [...] --to "destination path"'
        echo '  gitdll --themes "source path" [...] --to "destination path"'
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
  # ---- gitdll-plugins -> Download Obsidian plugins ---- #
  # -----------------------------------------------------------------
  gitdll-plugins = {
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
              set line (string trim "$line")

              if test -z "$line"
                  continue
              end

              if string match -q '#*' "$line"
                  continue
              end

              set repositories $repositories "$line"
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
                  -exec grep -lFx "$canonical_repository_url" {} \; \
                  2>/dev/null |
              command head -n 1
          )

          if test -n "$existing_repository_file"
              set existing_plugin_directory (
                  dirname "$existing_repository_file"
              )

              if test -f "$existing_plugin_directory/manifest.json"; and \
                      test -f "$existing_plugin_directory/main.js"

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
                  'if (.id | type) == "string" then .id else empty end' \
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

          if test -d "$plugin_directory"
              if test -f "$plugin_directory/manifest.json"; and \
                      test -f "$plugin_directory/main.js"; and \
                      test -f "$plugin_directory/repository-url.txt"

                  echo
                  echo "Skipping:"
                  echo "  $plugin_id (already complete)"
                  command rm -rf -- "$temporary_directory"
                  continue
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

          if not test -f "$plugin_stage/manifest.json"
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
                          if test -f "$plugin_stage/$release_asset_name"
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
              if test -f "$plugin_stage/$expected_file"
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

          if not test -f "$plugin_stage/main.js"
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

              command cp -f \
                  "$readme" \
                  "$plugin_stage/$readme_output"

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
  # ---- gitdll-themes -> Download Obsidian themes ---- #
  # -----------------------------------------------------------------
  gitdll-themes = {
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
              set line (string trim "$line")

              if test -z "$line"
                  continue
              end

              if string match -q '#*' "$line"
                  continue
              end

              set repositories $repositories "$line"
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
                  -exec grep -lFx "$canonical_repository_url" {} \; \
                  2>/dev/null |
              command head -n 1
          )

          if test -n "$existing_repository_file"
              set existing_theme_directory (
                  dirname "$existing_repository_file"
              )

              if test -f "$existing_theme_directory/theme.css"
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
                      'if (.id | type) == "string" then .id else empty end' \
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
              if test -f "$theme_directory/theme.css"; and \
                      test -f "$theme_directory/repository-url.txt"

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
              if not test -f "$theme_stage/manifest.json"
                  command cp -f \
                      "$manifest" \
                      "$theme_stage/manifest.json"
              end

              set saved_files manifest.json
          end

          if test -f "$source_theme_css"
              if not test -f "$theme_stage/theme.css"
                  command cp -f \
                      "$source_theme_css" \
                      "$theme_stage/theme.css"
              end

              set saved_files $saved_files theme.css
          else
              if not test -f "$theme_stage/theme.css"
                  command cp -f \
                      "$source_obsidian_css" \
                      "$theme_stage/theme.css"
              end

              set saved_files $saved_files theme.css
              set source_obsidian_css

              echo "Notice: obsidian.css was saved as theme.css."
          end

          if test -f "$source_obsidian_css"
              if not test -f "$theme_stage/obsidian.css"
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
                      '(?i)(screenshot|screen|screencap|preview|previews).+\.(png|jpe?g|gif|webp|svg)$' \
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

              command cp -f \
                  "$readme" \
                  "$theme_stage/$readme_output"

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

                          command cp -f \
                              "$local_image" \
                              "$theme_stage/$image_path"

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

      set --local missing_entries
      set --local missing_report "$HOME/Downloads/obsidian-missing.txt"

      for library_entry in "$library_root"/*
        if not test -d "$library_entry"
          continue
        end

        set --local entry_name (
          basename "$library_entry"
        )

        set --local repository_file \
          "$library_entry/repository-url.txt"

        if test -f "$repository_file"; or \
            test -f "$library_entry/repo/repository-url.txt"
          continue
        end

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

        set --local library_id (
          command jq -r \
            'if (.id | type) == "string" then .id else empty end' \
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

        set --local github_owner (
          string replace -r \
            '^https?://github\\.com/([^/]+)/?.*$' \
            '$1' \
            -- \
            "$author_url"
        )

        if test "$github_owner" = "$author_url"
          set github_owner "$author"
        end

        set --local has_github_owner 0

        if string match -rq '^[A-Za-z0-9-]+$' "$github_owner"
          set has_github_owner 1
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

        # First try the deterministic author-and-id repository URL.
        if test "$has_github_owner" -eq 1; and \
            string match -rq '^[A-Za-z0-9._-]+$' "$library_id"
          set --local direct_repository_url (
            command gh api \
              "repos/$github_owner/$library_id" \
              --jq .html_url \
              2>/dev/null
          )

          if test $status -eq 0; and test -n "$direct_repository_url"
            printf '%s\n' "$direct_repository_url" >"$repository_file"
            echo "Saved $repository_file"
            continue
          end
        end

        set --local candidates

        if test "$has_github_owner" -eq 1
          set candidates (
            command gh api \
              "users/$github_owner/repos?per_page=100&type=owner" \
              --jq \
              ".[] | select(.archived | not) | (.name | ascii_downcase) as \$name | (\$name | gsub(\"[^a-z0-9]\"; \"\")) as \$normalized_name | select((\$normalized_name | contains(\"$normalized_id\")) or (\"$normalized_id\" | contains(\$normalized_name)) or (\$name | contains(\"obsidian\"))) | [\"$github_owner/\" + .name, .html_url] | @tsv" \
              2>/dev/null
          )
        else
          set candidates (
            command gh api \
              --method GET \
              search/repositories \
              -f "q=$library_id in:name" \
              -f per_page=100 \
              --jq \
              '.items[]? | select(.archived | not) | [.owner.login + "/" + .name, .html_url] | @tsv' \
              2>/dev/null
          )
        end

        if test (count $candidates) -eq 0
          set --append missing_entries \
            "$entry_name — no matching GitHub repository found"
          continue
        end

        set --local exact_url

        for candidate in $candidates
          set --local candidate_parts (
            string split \t "$candidate"
          )

          if test (count $candidate_parts) -lt 2
            continue
          end

          set --local candidate_manifest_id (
            command gh api \
              "repos/$candidate_parts[1]/contents/manifest.json" \
              --jq .content \
              2>/dev/null |
            command tr -d '\n' |
            command base64 -D \
              2>/dev/null |
            command jq -r \
              'if (.id | type) == "string" then .id else empty end' |
            string trim
          )

          if test "$candidate_manifest_id" = "$library_id"
            set exact_url "$candidate_parts[2]"
            break
          end
        end

        if test -n "$exact_url"
          set --local selected_url "$exact_url"
        else
          set --local candidate_urls
          set --local candidate_index 1

          echo "Choose a repository for $entry_name:"
          echo "  local id: $library_id"
          echo "  local author: $author"

          for candidate in $candidates
            set --local candidate_parts (
              string split \t "$candidate"
            )

            if test (count $candidate_parts) -lt 2
              continue
            end

            set --append candidate_urls "$candidate_parts[2]"
            echo "  $candidate_index) $candidate_parts[1]"
            echo "     $candidate_parts[2]"

            set candidate_index (
              math "$candidate_index + 1"
            )
          end

          if test (count $candidate_urls) -eq 1
            set --local selected_url "$candidate_urls[1]"
          else
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

            set --local selected_url "$candidate_urls[$selection]"
          end
        end

        printf '%s\n' "$selected_url" >"$repository_file"
        echo "Saved $repository_file"
      end

      if test (count $missing_entries) -gt 0
        printf '%s\n' $missing_entries >"$missing_report"
        echo "Unmatched entries:"
        echo "  $missing_report"
      else
        printf '%s\n' "All scanned entries were matched." >"$missing_report"
        echo "All scanned entries were matched."
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
    # Scans Downloads plus the permanent Obsidian plugin or
    # theme library and writes repository-url.txt into folders
    # where the repository can be resolved.
    #
    # Examples:
    # resolve-obsidian-repos plugins
    # resolve-obsidian-repos themes
    # resolve-obsidian-repos all
    # -----------------------------------------------------------------
    resolve-obsidian-repos = {
      description = "Find and save GitHub repository URLs for Obsidian plugins and themes";

      body = ''
        set --local resolver_script "/Users/ven/Downloads/resolve-obsidian-repositories.py"

        set --local downloads_root "/Users/ven/Downloads"

        set --local plugins_root "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/data-backups/app-backups/obsidian/obsidian_extensions"

        set --local themes_root "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/data-backups/app-backups/obsidian/obsidian_themes"

        if not test -f "$resolver_script"
          echo "Resolver script not found:"
          echo "$resolver_script"
          return 1
        end

        /usr/bin/env python3 \
          "$resolver_script" \
          $argv \
          --downloads "$downloads_root" \
          --plugins-root "$plugins_root" \
          --themes-root "$themes_root"
      '';
    };
    # -----------------------------------------------------------------
  };
}
