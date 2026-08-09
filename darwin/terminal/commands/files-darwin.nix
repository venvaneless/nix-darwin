# darwin/terminal/commands/files-darwin.nix
#
# =====================================================================
# FISH FUNCTIONS: DARWIN FILES AND FOLDERS
#
# Keeps iCloud folder navigation and ditto-backed copying on macOS.
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
    # -----------------------------------------------------------------
    # ---- cdf -> Folder picker with fzf ---- #
    # Navigate folders from HOME using fzf
    # Includes iCloud Drive and iCloud container folders
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
            set -a rows (__cdf_add_row "iCloud" "$mobile_docs" "icloud-menu")
            set -a rows (__cdf_add_row "Application Support" "$app_support" "folder")
            set -a rows (__cdf_add_row "Preferences" "$preferences" "folder")
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

      /usr/bin/ditto "$src" "$dest"; or begin
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
  };
}
