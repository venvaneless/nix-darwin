# shared/terminal/commands/files-folders.nix
#
# =====================================================================
# FISH FUNCTIONS: FILES AND FOLDERS
# =====================================================================

{ config, lib, pkgs, ... }:

let
  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;

  # Provides portable folder navigation and copying helpers.
  installOn = {
    darwin = true;
    linux = true;
  };

  enabledForCurrentSystem =
    (isDarwin && installOn.darwin) || (isLinux && installOn.linux);

  # macOS preserves Finder metadata with ditto. GNU cp provides the
  # equivalent recursive, attribute-preserving copy behavior on Linux.
  copyCommand =
    if isDarwin then
      "/usr/bin/ditto"
    else
      "${pkgs.coreutils}/bin/cp -a --";

  # iCloud and Library roots exist only on macOS. The normal HOME folders
  # remain available to cdf on both supported platforms.
  darwinRootRows = lib.optionalString isDarwin ''
    if test -d "$mobile_docs"
      set -a rows (__cdf_add_row "iCloud" "$mobile_docs" "icloud-menu")
    end

    if test -d "$app_support"
      set -a rows (__cdf_add_row "Application Support" "$app_support" "folder")
    end

    if test -d "$preferences"
      set -a rows (__cdf_add_row "Preferences" "$preferences" "folder")
    end
  '';
in
{
  config = lib.mkIf enabledForCurrentSystem {
    programs.fish.functions = {
      # -----------------------------------------------------------------
      # ---- cdf -> Folder picker with fzf ---- #
      # Navigate folders from HOME using fzf.
      # Includes macOS iCloud and Library folders when they are available.
      #
      # Controls:
      # ENTER       cd into selected folder
      # RIGHT/CTRL-L enter highlighted folder
      # LEFT/CTRL-H  go to parent folder
      #
      # Example:
      # cdf
      # -----------------------------------------------------------------
      cdf = ''
        set home_path "$HOME"
        set mobile_docs "$HOME/Library/Mobile Documents"
        set icloud_drive "$mobile_docs/com~apple~CloudDocs"
        set app_support "$HOME/Library/Application Support"
        set preferences "$HOME/Library/Preferences"

        set show_hidden "no"

        set current_kind "root"
        set current_path "$home_path"

        set stack_kind
        set stack_path

        function __cdf_pretty_container_name
          set raw (basename "$argv[1]")
          set clean "$raw"

          set clean (string replace -r '^iCloud~' "" "$clean")
          set clean (string replace -r '^[A-Z0-9]+~' "" "$clean")
          set clean (string replace -r '^com~apple~' "" "$clean")

          set parts (string split "~" "$clean")
          set label "$parts[-1]"

          echo "$label"
        end

        function __cdf_add_row
          printf "%s\t%s\t%s\n" "$argv[1]" "$argv[2]" "$argv[3]"
        end

        function __cdf_should_skip_hidden
          set base (basename "$argv[1]")

          if test "$show_hidden" = "no"
            if string match -q ".*" "$base"
              return 0
            end
          end

          return 1
        end

        while true
          set rows

          switch "$current_kind"
            case root
              set -a rows (__cdf_add_row "Home" "$home_path" "folder")

              for directory_name in Desktop Documents Downloads
                set directory_path "$home_path/$directory_name"

                if test -d "$directory_path"
                  set -a rows (__cdf_add_row "$directory_name" "$directory_path" "folder")
                end
              end

              ${darwinRootRows}
              set -a rows (__cdf_add_row "Show Hidden Files: $show_hidden" "$current_path" "toggle-hidden")

            case icloud-menu
              set -a rows (__cdf_add_row "All Folders" "$mobile_docs" "icloud-all")
              set -a rows (__cdf_add_row "App Containers" "$mobile_docs" "icloud-containers")

            case icloud-all
              if test -d "$icloud_drive"
                for dir in (find "$icloud_drive" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                  if __cdf_should_skip_hidden "$dir"
                    continue
                  end

                  set name (basename "$dir")
                  set -a rows (__cdf_add_row "$name" "$dir" "folder")
                end
              end

              if test -d "$mobile_docs"
                for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                  if __cdf_should_skip_hidden "$dir"
                    continue
                  end

                  set base (basename "$dir")

                  if test "$base" = "com~apple~CloudDocs"
                    continue
                  end

                  set name (__cdf_pretty_container_name "$dir")
                  set -a rows (__cdf_add_row "$name" "$dir" "folder")
                end
              end

            case icloud-containers
              if test -d "$mobile_docs"
                for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                  if __cdf_should_skip_hidden "$dir"
                    continue
                  end

                  set base (basename "$dir")

                  if test "$base" = "com~apple~CloudDocs"
                    continue
                  end

                  set name (__cdf_pretty_container_name "$dir")
                  set -a rows (__cdf_add_row "$name" "$dir" "folder")
                end
              end

            case folder
              if test -d "$current_path"
                for dir in (find "$current_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                  if __cdf_should_skip_hidden "$dir"
                    continue
                  end

                  set name (basename "$dir")
                  set -a rows (__cdf_add_row "$name" "$dir" "folder")
                end
              end
          end

          set prompt_name (basename "$current_path")

          set result (
            printf "%s\n" $rows |
            fzf \
              --header="cdf: $current_path" \
              --height=80% \
              --layout=reverse-list \
              --prompt="$prompt_name > " \
              --delimiter=(printf "\t") \
              --with-nth=1 \
              --expect=enter,right,left,ctrl-l,ctrl-h \
              --preview='test -d {2:q} && eza -la --icons=always {2:q} 2>/dev/null || true'
          )

          if test (count $result) -eq 0
            return 0
          end

          set key $result[1]
          set row $result[2]

          if test -z "$row"
            continue
          end

          set fields (string split (printf "\t") "$row")
          set selected_name "$fields[1]"
          set selected_path "$fields[2]"
          set selected_kind "$fields[3]"

          if test "$selected_kind" = "toggle-hidden"
            read -l -P "Show hidden files? [y/N]: " answer

            if string match -qi "y" "$answer"; or string match -qi "yes" "$answer"
              set show_hidden "yes"
            else
              set show_hidden "no"
            end

            continue
          end

          switch "$key"
            case enter
              if test "$selected_kind" = "folder"
                builtin cd "$selected_path"
                return 0
              else
                set -a stack_kind "$current_kind"
                set -a stack_path "$current_path"

                set current_kind "$selected_kind"
                set current_path "$selected_path"
              end

            case right ctrl-l
              set -a stack_kind "$current_kind"
              set -a stack_path "$current_path"

              set current_kind "$selected_kind"
              set current_path "$selected_path"

            case left ctrl-h
              if test (count $stack_kind) -gt 0
                set current_kind "$stack_kind[-1]"
                set current_path "$stack_path[-1]"

                set -e stack_kind[-1]
                set -e stack_path[-1]
              else
                set current_kind "root"
                set current_path "$home_path"
              end
          end
        end
      '';
      # -----------------------------------------------------------------

      # -----------------------------------------------------------------
      # ---- copyf -> Copy to an explicit destination path ---- #
      #
      # Example:
      # copyf ./source-folder ./destination-folder
      # -----------------------------------------------------------------
      copyf = ''
        set -l src (string replace -r '/+$' "" -- "$argv[1]")
        set -l dest (string replace -r '/+$' "" -- "$argv[2]")

        if test -z "$src"; or test -z "$dest"; or not test -e "$src"
          echo "Usage: copyf <path/to/file/or/folder> <destination/path>"
          return 1
        end

        if test -e "$dest"
          echo "Destination already exists: $dest"
          return 1
        end

        mkdir -p (dirname "$dest"); or begin
          echo "Could not create destination parent:"
          echo (dirname "$dest")
          return 1
        end

        ${copyCommand} "$src" "$dest"; or begin
          echo "Copy failed: $src"
          return 1
        end

        echo "Copied: $src -> $dest"
      '';

      # Alias for copyf
      # -----------------------------------------------------------------
      copyfolder = ''
        copyf $argv
      '';

      # -----------------------------------------------------------------
      # ---- zz -> Pick zoxide path with fzf ---- #
      # Shows zoxide tracked paths in fzf.
      # Press ENTER to cd into the selected path.
      #
      # Example:
      # zz
      # -----------------------------------------------------------------
      zz = ''
        set selected_path (
          zoxide query -l |
          fzf --height=60% --reverse --prompt="zoxide cd> "
        )

        if test -z "$selected_path"
          return 0
        end

        builtin cd "$selected_path"
      '';
      # -----------------------------------------------------------------


      # -----------------------------------------------------------------
      # ---- unarchive -> Extract archives and remove on success ---- #
      # Extracts one or more archives without spilling files directly
      # into the archive's parent folder.
      #
      # If an archive already contains a matching root folder, that folder
      # is preserved. Otherwise, contents are placed inside a folder named
      # after the archive.
      #
      # Deletes each archive only after successful extraction and placement.
      # Failed archives are kept and reported after processing finishes.
      #
      # Supported formats:
      # .tar
      # .tar.gz / .tgz
      # .tar.bz2 / .tbz2 / .tbz
      # .tar.xz / .txz
      # .tar.zst / .tzst
      # .zip
      #
      # Examples:
      # unarchive ~/Downloads/archive.tar
      # unarchive ~/Downloads/archive-1.tar.gz ~/Downloads/archive-2.zip
      # -----------------------------------------------------------------
      unarchive = ''
        if test (count $argv) -eq 0
          echo "Usage: unarchive <archive> [archive ...]"
          return 1
        end

        set -l failed_archives

        for input in $argv
          set -l archive (realpath "$input")

          if not test -f "$archive"
            echo "Archive not found: $input"
            set -a failed_archives "$input"
            continue
          end

          set -l parent (dirname "$archive")
          set -l filename (basename "$archive")
          set -l folder_name "$filename"

          switch "$folder_name"
            case '*.tar.gz'
              set folder_name (string replace -r '\.tar\.gz$' "" "$folder_name")
            case '*.tar.bz2'
              set folder_name (string replace -r '\.tar\.bz2$' "" "$folder_name")
            case '*.tar.xz'
              set folder_name (string replace -r '\.tar\.xz$' "" "$folder_name")
            case '*.tar.zst'
              set folder_name (string replace -r '\.tar\.zst$' "" "$folder_name")
            case '*.tgz'
              set folder_name (string replace -r '\.tgz$' "" "$folder_name")
            case '*.tbz2'
              set folder_name (string replace -r '\.tbz2$' "" "$folder_name")
            case '*.tbz'
              set folder_name (string replace -r '\.tbz$' "" "$folder_name")
            case '*.txz'
              set folder_name (string replace -r '\.txz$' "" "$folder_name")
            case '*.tzst'
              set folder_name (string replace -r '\.tzst$' "" "$folder_name")
            case '*.tar'
              set folder_name (string replace -r '\.tar$' "" "$folder_name")
            case '*.zip'
              set folder_name (string replace -r '\.zip$' "" "$folder_name")
          end

          set -l destination "$parent/$folder_name"
          set -l temp_dir (mktemp -d "$parent/.unarchive.XXXXXX")

          if test $status -ne 0
            echo "Could not create temporary extraction folder:"
            echo "$archive"
            set -a failed_archives "$archive"
            continue
          end

          set -l extract_status 1

          switch "$archive"
            case '*.tar.gz' '*.tgz' \
                 '*.tar.bz2' '*.tbz2' '*.tbz' \
                 '*.tar.xz' '*.txz' \
                 '*.tar.zst' '*.tzst' \
                 '*.tar'

              tar -xf "$archive" -C "$temp_dir"
              set extract_status $status

            case '*.zip'
              unzip -q "$archive" -d "$temp_dir"
              set extract_status $status

            case '*'
              echo "Unsupported archive format: $archive"
              rm -rf "$temp_dir"
              set -a failed_archives "$archive"
              continue
          end

          if test $extract_status -ne 0
            echo "Extraction failed. Archive kept:"
            echo "$archive"

            rm -rf "$temp_dir"
            set -a failed_archives "$archive"
            continue
          end

          set -l extracted_items "$temp_dir"/*

          if test (count $extracted_items) -eq 1
            if test -d "$extracted_items[1]"
              if test (basename "$extracted_items[1]") = "$folder_name"
                if test -e "$destination"
                  echo "Destination already exists. Archive kept:"
                  echo "$destination"

                  rm -rf "$temp_dir"
                  set -a failed_archives "$archive"
                  continue
                end

                mv "$extracted_items[1]" "$destination"
                set -l move_status $status

                rm -rf "$temp_dir"

                if test $move_status -ne 0
                  echo "Could not move extracted folder. Archive kept:"
                  echo "$archive"

                  set -a failed_archives "$archive"
                  continue
                end
              else
                if test -e "$destination"
                  echo "Destination already exists. Archive kept:"
                  echo "$destination"

                  rm -rf "$temp_dir"
                  set -a failed_archives "$archive"
                  continue
                end

                mv "$temp_dir" "$destination"

                if test $status -ne 0
                  echo "Could not place extracted contents. Archive kept:"
                  echo "$archive"

                  rm -rf "$temp_dir"
                  set -a failed_archives "$archive"
                  continue
                end
              end
            else
              if test -e "$destination"
                echo "Destination already exists. Archive kept:"
                echo "$destination"

                rm -rf "$temp_dir"
                set -a failed_archives "$archive"
                continue
              end

              mv "$temp_dir" "$destination"

              if test $status -ne 0
                echo "Could not place extracted contents. Archive kept:"
                echo "$archive"

                rm -rf "$temp_dir"
                set -a failed_archives "$archive"
                continue
              end
            end
          else
            if test -e "$destination"
              echo "Destination already exists. Archive kept:"
              echo "$destination"

              rm -rf "$temp_dir"
              set -a failed_archives "$archive"
              continue
            end

            mv "$temp_dir" "$destination"

            if test $status -ne 0
              echo "Could not place extracted contents. Archive kept:"
              echo "$archive"

              rm -rf "$temp_dir"
              set -a failed_archives "$archive"
              continue
            end
          end

          rm -f "$archive"; or begin
            echo "Archive extracted, but could not be deleted:"
            echo "$archive"

            set -a failed_archives "$archive"
            continue
          end

          echo "Extracted: $destination"
          echo "Removed:   $archive"
        end

        if test (count $failed_archives) -gt 0
          echo
          echo "Failed archives:"

          for archive in $failed_archives
            echo "$archive"
          end

          return 1
        end
      '';
      # -----------------------------------------------------------------
    };
  };
}
