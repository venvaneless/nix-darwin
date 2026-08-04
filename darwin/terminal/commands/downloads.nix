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

        if test "$mode" = "--plugins"
          if not functions -q gitdll-plugins
            echo "Error: gitdll-plugins is not available."
            return 1
          end

          set --local library_type plugins
          set --local downloader_function gitdll-plugins
          set --local downloader_output_directory gitdll-plugins
          set --local missing_report_name \
            missing-plugin-repository-urls.txt
          set --local failed_report_name \
            failed-plugin-downloads.txt
        else
          if not functions -q gitdll-themes
            echo "Error: gitdll-themes is not available."
            return 1
          end

          set --local library_type themes
          set --local downloader_function gitdll-themes
          set --local downloader_output_directory gitdll-themes
          set --local missing_report_name \
            missing-theme-repository-urls.txt
          set --local failed_report_name \
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

        set --local temporary_home \
          "$temporary_directory/home"

        set --local temporary_downloads \
          "$temporary_home/Downloads"

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

        command mkdir -p -- "$temporary_downloads"

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

        set --local source_count 0
        set --local repository_count 0
        set --local missing_count 0

        for source_input in $source_inputs
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

          set --local manifest_file \
            "$source_folder/manifest.json"

          if test -f "$manifest_file"
            set --local manifest_id (
              /usr/bin/python3 - "$manifest_file" <<'PY'
import json
import sys

path = sys.argv[1]

try:
    with open(path, "r", encoding="utf-8") as file:
        data = json.load(file)

    value = str(data.get("id", "")).strip()

    if value:
        print(value)
except Exception:
    pass
PY
            )

            if test -n "$manifest_id"
              set source_name "$manifest_id"
            end
          end

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
          echo
          echo "Error: No usable repository URLs were found."
          command rm -rf -- "$temporary_directory"
          return 1
        end

        echo
        echo "Downloading fresh copies..."
        echo

        env \
          HOME="$temporary_home" \
          fish \
          --no-config \
          --command '
            source "$argv[1]"
            $argv[2] "$argv[3]"
          ' \
          "$function_file" \
          "$downloader_function" \
          "$repositories_file"

        set --local downloader_status $status

        set --local generated_root \
          "$temporary_downloads/$downloader_output_directory"

        set --local downloaded_count 0
        set --local skipped_existing_count 0
        set --local move_failed_count 0

        if test -d "$generated_root"
          for generated_folder in "$generated_root"/*
            if not test -d "$generated_folder"
              continue
            end

            set --local generated_name (
              basename "$generated_folder"
            )

            set --local final_folder \
              "$destination/$generated_name"

            if test -e "$final_folder"; or test -L "$final_folder"
              echo
              echo "Skipping existing destination:"
              echo "  $final_folder"

              set skipped_existing_count (
                math "$skipped_existing_count + 1"
              )

              continue
            end

            if command mv \
                -- \
                "$generated_folder" \
                "$final_folder"

              echo
              echo "Moved:"
              echo "  $final_folder"

              set downloaded_count (
                math "$downloaded_count + 1"
              )
            else
              echo
              echo "Error: Could not move downloaded folder:"
              echo "  $generated_folder"
              echo "To:"
              echo "  $final_folder"

              set move_failed_count (
                math "$move_failed_count + 1"
              )
            end
          end
        end

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

        echo
        echo "============================================================"
        echo "DOWNLOAD SUMMARY"
        echo "============================================================"
        echo "Downloaded:              $downloaded_count"
        echo "Destination already had: $skipped_existing_count"
        echo "Move failures:           $move_failed_count"
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

        if test "$downloader_status" -ne 0
          return "$downloader_status"
        end

        if test "$move_failed_count" -gt 0
          return 1
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


      if not command -q unzip
          echo "Error: unzip is not installed."
          return 1
      end

      if not command -q tar
          echo "Error: tar is not installed."
          return 1
      end


      if not command -q unzip
          echo "Error: unzip is not installed."
          return 1
      end

      if not command -q tar
          echo "Error: tar is not installed."
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

          set repository_archive \
              "$temporary_directory/repository.zip"

          set repository_extract \
              "$temporary_directory/repository"

          if not command curl \
                  --fail \
                  --location \
                  --silent \
                  --show-error \
                  --output "$repository_archive" \
                  "$canonical_repository_url/archive/HEAD.zip"

              echo "Error: Could not download the repository."
              command rm -rf -- "$temporary_directory"
              continue
          end

          command mkdir -p -- "$repository_extract"

          if not command unzip \
                  -q \
                  "$repository_archive" \
                  -d "$repository_extract"

              echo "Error: Could not extract the repository."
              command rm -rf -- "$temporary_directory"
              continue
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

          if test -d "$plugin_directory"
              echo
              echo "Skipping:"
              echo "  $plugin_id (already exists)"
              command rm -rf -- "$temporary_directory"
              continue
          end

          set plugin_stage "$temporary_directory/plugin"
          command mkdir -p -- "$plugin_stage"

          command cp -f \
              "$manifest" \
              "$plugin_stage/manifest.json"

          set saved_files manifest.json

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

                      case '*.zip'
                          set release_zip \
                              "$temporary_directory/$release_asset_name"

                          if command curl \
                                  --fail \
                                  --location \
                                  --silent \
                                  --show-error \
                                  --output "$release_zip" \
                                  "$release_asset_url"

                              set release_extract \
                                  "$temporary_directory/release-zip"

                              command mkdir -p -- "$release_extract"

                              if command unzip \
                                      -q \
                                      "$release_zip" \
                                      -d "$release_extract"

                                  for expected_file in \
                                          main.js \
                                          styles.css \
                                          manifest.json

                                      set extracted_file (
                                          command find "$release_extract" \
                                              -type f \
                                              -name "$expected_file" \
                                              -not -path "*/node_modules/*" \
                                              -print \
                                              -quit
                                      )

                                      if test -n "$extracted_file"
                                          command cp -f \
                                              "$extracted_file" \
                                              "$plugin_stage/$expected_file"

                                          if not contains \
                                                  "$expected_file" \
                                                  $saved_files

                                              set saved_files \
                                                  $saved_files \
                                                  "$expected_file"
                                          end
                                      end
                                  end
                              else
                                  echo \
                                      "Notice: Could not extract release asset: $release_asset_name"
                              end
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

          if not command mv \
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
      set destination "$HOME/Downloads/gitdll-themes"

      if test (count $argv) -eq 0
          echo "Usage:"
          echo '  gitdll-themes <links.txt>'
          echo '  gitdll-themes "https://github.com/owner/repository" [...]'
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

      if not command -q unzip
          echo "Error: unzip is not installed."
          return 1
      end

      set repositories

      if test (count $argv) -eq 1; and test -f "$argv[1]"
          while read -l line
              set line (string trim "$line")

              if test -z "$line"
                  continue
              end

              if string match -q '#*' "$line"
                  continue
              end

              set repositories $repositories "$line"
          end < "$argv[1]"
      else
          set repositories $argv
      end

      if test (count $repositories) -eq 0
          echo "Error: No repository links were found."
          return 1
      end

      command mkdir -p -- "$destination"

      for repository_url in $repositories
          set repository_path (
              string replace -r '^https?://github\.com/' ''' "$repository_url" |
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

          set archive "$temporary_directory/repository.zip"
          set extracted "$temporary_directory/repository"

          if not command curl \
                  --fail \
                  --location \
                  --silent \
                  --show-error \
                  "$canonical_repository_url/archive/HEAD.zip" \
                  >"$archive"

              echo "Error: Could not download the repository."
              command rm -rf -- "$temporary_directory"
              continue
          end

          command mkdir -p "$extracted"

          if not command unzip \
                  -q \
                  "$archive" \
                  -d "$extracted"

              echo "Error: Could not extract the repository."
              command rm -rf -- "$temporary_directory"
              continue
          end

          set manifest (
              command find "$extracted" \
                  -type f \
                  -name "manifest.json" \
                  -not -path "*/node_modules/*" \
                  -print \
                  -quit
          )

          set manifest_was_generated 0

          if test -z "$manifest"
              set manifest \
                  "$temporary_directory/generated-manifest.json"

              if not command jq -n \
                      --arg name "$fallback_folder_name" \
                      --arg author "$repository_owner" \
                      '{
                          name: $name,
                          version: "0.0.0",
                          minAppVersion: "0.0.0",
                          author: $author,
                          gitdllThemesGeneratedManifest: true
                      }' \
                      >"$manifest"

                  echo "Error: Could not create a fallback manifest.json."
                  command rm -rf -- "$temporary_directory"
                  continue
              end

              set manifest_was_generated 1

              echo \
                  "Notice: manifest.json was not in the repository; created a marked local fallback."
          else if not command jq -e . "$manifest" >/dev/null
              echo "Error: manifest.json is invalid."
              command rm -rf -- "$temporary_directory"
              continue
          end

          set manifest_directory (dirname "$manifest")

          set theme_id (
              command jq -r \
                  'if (.id | type) == "string" then .id else empty end' \
                  "$manifest" |
              string trim
          )

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

          if test -d "$theme_directory"
              echo
              echo "Skipping:"
              echo "  $theme_folder_name (already exists)"
              command rm -rf -- "$temporary_directory"
              continue
          end

          set theme_stage "$temporary_directory/theme"

          command mkdir -p -- "$theme_stage"

          command cp -f \
              "$manifest" \
              "$theme_stage/manifest.json"

          set saved_files manifest.json

          if test -f "$source_theme_css"
              command cp -f \
                  "$source_theme_css" \
                  "$theme_stage/theme.css"

              set saved_files $saved_files theme.css
          else
              command cp -f \
                  "$source_obsidian_css" \
                  "$theme_stage/theme.css"

              set saved_files $saved_files theme.css
              set source_obsidian_css

              echo "Notice: obsidian.css was saved as theme.css."
          end

          if test -f "$source_obsidian_css"
              command cp -f \
                  "$source_obsidian_css" \
                  "$theme_stage/obsidian.css"

              set saved_files $saved_files obsidian.css
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

          if not command mv \
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

          if test "$manifest_was_generated" -eq 1
              echo \
                  "  (manifest.json was generated locally and marked)"
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
