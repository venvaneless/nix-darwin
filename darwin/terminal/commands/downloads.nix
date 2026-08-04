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
  # ---- gitdll -> Download one or more Git repositories ---- #
  #
  # Accepts:
  # - One or more repository links
  # - One or more text files containing repository links
  # - A mixture of links and text files
  #
  # Blank lines and lines beginning with # in text files are ignored.
  #
  # Downloads into:
  # ~/Downloads/gitdll
  #
  # Examples:
  # gitdll "https://github.com/owner/repository"
  # gitdll "https://github.com/owner/one" "https://github.com/owner/two"
  # gitdll links.txt
  # gitdll links-one.txt links-two.txt
  # -----------------------------------------------------------------
  gitdll = {
    description = "Download one or more Git repositories";

    body = ''
      set --local destination "$HOME/Downloads/gitdll"

      if test (count $argv) -eq 0
        echo "Usage:"
        echo '  gitdll "https://github.com/owner/repository" [...]'
        echo "  gitdll <links.txt> [more-links-or-files ...]"
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
          end < "$source"
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
      set destination "$HOME/Downloads/gitdll-plugins"

      if test (count $argv) -eq 0
          echo "Usage:"
          echo '  gitdll-plugins <links.txt>'
          echo '  gitdll-plugins "https://github.com/owner/repository" [...]'
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
