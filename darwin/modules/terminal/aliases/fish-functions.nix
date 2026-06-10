# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/fish-functions.nix
#
# FISH FUNCTIONS
# =============================================================
# Custom reusable Fish shell functions
# =============================================================

{ ... }:

{
  programs.fish.functions = {
    # ---------- General Fish Functions ---------- #

    # ---------------------------------------------------------
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
    # ---------------------------------------------------------
    cdf = ''
      set home_path "$HOME"
      set mobile_docs "$HOME/Library/Mobile Documents"
      set icloud_drive "$mobile_docs/com~apple~CloudDocs"
      set app_support "$HOME/Library/Application Support"
      set preferences "$HOME/Library/Preferences"
    
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
    
      while true
        set rows
    
        switch "$current_kind"
          case root
            set -a rows (__cdf_add_row "Home" "$home_path" "folder")
            set -a rows (__cdf_add_row "iCloud" "$mobile_docs" "icloud-menu")
            set -a rows (__cdf_add_row "Application Support" "$app_support" "folder")
            set -a rows (__cdf_add_row "Preferences" "$preferences" "folder")
    
          case icloud-menu
            set -a rows (__cdf_add_row "All Folders" "$mobile_docs" "icloud-all")
            set -a rows (__cdf_add_row "App Containers" "$mobile_docs" "icloud-containers")
    
          case icloud-all
            if test -d "$icloud_drive"
              for dir in (find "$icloud_drive" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                set name (basename "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end
    
            if test -d "$mobile_docs"
              for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                set base (basename "$dir")
    
                if test "$base" = "com~apple~CloudDocs"
                  continue
                end
    
                if test "$base" = ".Trash"
                  continue
                end
    
                set name (__cdf_pretty_container_name "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end
    
          case icloud-containers
            if test -d "$mobile_docs"
              for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                set base (basename "$dir")
    
                if test "$base" = "com~apple~CloudDocs"
                  continue
                end
    
                if test "$base" = ".Trash"
                  continue
                end
    
                set name (__cdf_pretty_container_name "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end
    
          case folder
            if test -d "$current_path"
              for dir in (find "$current_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                set name (basename "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end
        end
    
        set result (
          printf "%s\n" $rows |
          fzf \
            --height=80% \
            --reverse \
            --delimiter=(printf "\t") \
            --with-nth=1 \
            --prompt="cdf: $current_path > " \
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
    # ---------------------------------------------------------
    

    # ---------------------------------------------------------
    # ---- zz -> Pick zoxide path with fzf and cd into it ---- #
    # Shows zoxide tracked paths in fzf
    # Press ENTER to cd into the selected path
    #
    # Example:
    # zz
    # ---------------------------------------------------------
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
    # ---------------------------------------------------------


    # ---------------------------------------------------------
    # ---- ftrash -> Trash manager with fzf ---- #
    # View or clean System Trash and iCloud container Trash
    # Does not delete the Trash folders themselves
    #
    # Options:
    # System Trash / View Trash
    # System Trash / Clean Trash
    # iCloud Trash / View Trash
    # iCloud Trash / Clean Trash
    #
    # Example:
    # ftrash
    # ---------------------------------------------------------
    ftrash = ''
      set system_trash "$HOME/.Trash"
      set icloud_root "$HOME/Library/Mobile Documents"

      function __ftrash_clean_dir
        set trash_dir "$argv[1]"

        if not test -d "$trash_dir"
          echo "Trash not found: $trash_dir"
          return 0
        end

        find "$trash_dir" -mindepth 1 -maxdepth 1 -print0 |
        while read -lz target
          echo "Deleting: $target"
          chflags -R nouchg,noschg "$target" 2>/dev/null; or true
          xattr -cr "$target" 2>/dev/null; or true
          rm -rf "$target" 2>/dev/null; or true
        end
      end

      set choice (
        printf "%s\n" \
          "System Trash / View Trash" \
          "System Trash / Clean Trash" \
          "iCloud Trash / View Trash" \
          "iCloud Trash / Clean Trash" |
        fzf --height=40% --reverse --prompt="trash> "
      )

      switch "$choice"
        case "System Trash / View Trash"
          eza -la --icons=always "$system_trash"

        case "System Trash / Clean Trash"
          __ftrash_clean_dir "$system_trash"

        case "iCloud Trash / View Trash"
          find "$icloud_root" -type d -name ".Trash" -print0 2>/dev/null |
          while read -lz trash_dir
            echo
            echo "Trash: $trash_dir"
            eza -la --icons=always "$trash_dir"
          end

        case "iCloud Trash / Clean Trash"
          find "$icloud_root" -type d -name ".Trash" -print0 2>/dev/null |
          while read -lz trash_dir
            echo "Cleaning: $trash_dir"
            __ftrash_clean_dir "$trash_dir"
          end
      end
    '';
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # ---- dtrash -> Force delete stubborn iCloud files ---- #
    # Force-remove files/folders that iCloud refuses to delete
    # Clears common macOS flags and extended attributes first
    #
    # Example:
    # dtrash ~/Library/Mobile\ Documents/com~apple~CloudDocs/file.txt
    # dtrash ./stuck-folder
    # ---------------------------------------------------------
    dtrash = ''
      if test (count $argv) -eq 0
        echo "Usage: dtrash <path> [path...]"
        return 1
      end

      for target in $argv
        if not test -e "$target"
          echo "Not found: $target"
          continue
        end

        echo "Force deleting: $target"

        # Remove macOS file flags that can block deletion
        chflags -R nouchg,noschg "$target" 2>/dev/null; or true

        # Remove extended attributes that can confuse iCloud/Finder
        xattr -cr "$target" 2>/dev/null; or true

        # Delete the target
        rm -rf "$target"

        if test -e "$target"
          echo "Normal delete failed, trying sudo..."
          sudo chflags -R nouchg,noschg "$target" 2>/dev/null; or true
          sudo xattr -cr "$target" 2>/dev/null; or true
          sudo rm -rf "$target"
        end

        if test -e "$target"
          echo "Failed to delete: $target"
          return 1
        else
          echo "Deleted: $target"
        end
      end
    '';
    # ---------------------------------------------------------


    # ---------------------------------------------------------
    # ---- strash -> Force delete Trash ---- #
    # Force-remove files/folders that iCloud refuses to delete
    # ---------------------------------------------------------
    strash = ''
      function __strash_delete_one
        set target "$argv[1]"
    
        if not test -e "$target"
          echo "Not found: $target"
          return 0
        end
    
        echo "Force deleting: $target"
    
        chflags -R nouchg,noschg "$target" 2>/dev/null; or true
        xattr -cr "$target" 2>/dev/null; or true
        rm -rf "$target" 2>/dev/null
    
        if test -e "$target"
          echo "Normal delete failed, trying sudo..."
          sudo chflags -R nouchg,noschg "$target" 2>/dev/null; or true
          sudo xattr -cr "$target" 2>/dev/null; or true
          sudo rm -rf "$target"
        end
    
        if test -e "$target"
          echo "Failed to delete: $target"
          return 1
        else
          echo "Deleted: $target"
        end
      end
    
      if test (count $argv) -gt 0
        for target in $argv
          __strash_delete_one "$target"; or return 1
        end
        return 0
      end
    
      echo "Cleaning system Trash contents..."
    
      if test -d "$HOME/.Trash"
        find "$HOME/.Trash" -mindepth 1 -maxdepth 1 -print0 |
        while read -lz target
          __strash_delete_one "$target"; or return 1
        end
      end
    
      echo "Cleaning iCloud container Trash contents..."
    
      find "$HOME/Library/Mobile Documents" -type d -name ".Trash" -print0 2>/dev/null |
      while read -lz trash_dir
        echo "Found Trash: $trash_dir"
    
        find "$trash_dir" -mindepth 1 -maxdepth 1 -print0 |
        while read -lz target
          __strash_delete_one "$target"; or return 1
        end
      end
    '';
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # ---- ia -> Internet Archive helper through mise Python ---- #
    # Download Internet Archive files by type
    #
    # Examples:
    # ia dll https://archive.org/details/NARA-26300439
    # ia dll pdf https://archive.org/details/NARA-26300439
    # ia dll epub https://archive.org/details/NARA-26300439
    # ---------------------------------------------------------
    ia = ''
      if test (count $argv) -eq 0
        echo "Usage:"
        echo "  ia dll <archive-url-or-id>"
        echo "  ia dll pdf <archive-url-or-id>"
        echo "  ia dll epub <archive-url-or-id>"
        return 1
      end

      switch $argv[1]
        case dll
          set filetype pdf
          set target ""

          if test (count $argv) -eq 2
            set target $argv[2]
          else if test (count $argv) -ge 3
            set filetype $argv[2]
            set target $argv[3]
          else
            echo "Usage: ia dll [pdf|epub] <archive-url-or-id>"
            return 1
          end

          set filetype (string replace -r '^\\.' "" "$filetype")

          if string match -q '*archive.org/details/*' "$target"
            set identifier (string replace -r '^.*archive\\.org/details/([^/?#]+).*$' '$1' "$target")
          else if string match -q '*archive.org/download/*' "$target"
            set identifier (string replace -r '^.*archive\\.org/download/([^/?#]+).*$' '$1' "$target")
          else
            set identifier "$target"
          end

          echo "Downloading .$filetype files from:"
          echo "$identifier"

          mise x python@3.12 -- ia download "$identifier" "--glob=*.$filetype"

        case '*'
          mise x python@3.12 -- ia $argv
      end
    '';
    # ---------------------------------------------------------
  };
}