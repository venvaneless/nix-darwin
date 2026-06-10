# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/fish-functions.nix
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
    # ---- cdf -> Navigate folders with fzf and cd into one ---- #
    # ENTER selects the current folder
    # RIGHT enters the highlighted folder
    # LEFT goes to the parent folder
    #
    # Example:
    # cdf
    # ---------------------------------------------------------
    cdf = ''
      set current "$HOME"

      while true
        set entries

        if test "$current" = "$HOME"
          set -a entries "[iCloud Drive]\t$HOME/iCloudDocs"
          set -a entries "[iCloud Containers]\t$HOME/Library/Mobile Documents"
        end

        set dirs (
          find "$current" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
          sort
        )

        for dir in $dirs
          set name (basename "$dir")
          set -a entries "$name\t$dir"
        end

        set result (
          printf "%s\n" $entries |
          fzf \
            --prompt="cdf: $current > " \
            --height=80% \
            --reverse \
            --delimiter="\t" \
            --with-nth=1 \
            --expect=enter,right,left \
            --preview='eza -la --icons=always {2} 2>/dev/null'
        )

        if test (count $result) -eq 0
          return 0
        end

        set key $result[1]
        set row $result[2]

        if test -z "$row"
          continue
        end

        set selected_path (string split "\t" "$row")[2]

        switch "$key"
          case enter
            builtin cd "$selected_path"
            return 0

          case right
            set current "$selected_path"

          case left
            set current (dirname "$current")
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
    # ---- ftrash -> Force delete stubborn iCloud files ---- #
    # Force-remove files/folders that iCloud refuses to delete
    # Clears common macOS flags and extended attributes first
    #
    # Example:
    # ftrash ~/Library/Mobile\ Documents/com~apple~CloudDocs/file.txt
    # ftrash ./stuck-folder
    # ---------------------------------------------------------
    ftrash = ''
      if test (count $argv) -eq 0
        echo "Usage: ftrash <path> [path...]"
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
    # ---- ftrash -> Force delete stubborn iCloud files ---- #
    # Force-remove files/folders that iCloud refuses to delete
    # ---------------------------------------------------------
    fstrash = ''
      function __fstrash_delete_one
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
          __ftrash_delete_one "$target"; or return 1
        end
        return 0
      end
    
      echo "Cleaning system Trash contents..."
    
      if test -d "$HOME/.Trash"
        find "$HOME/.Trash" -mindepth 1 -maxdepth 1 -print0 |
        while read -lz target
          __ftrash_delete_one "$target"; or return 1
        end
      end
    
      echo "Cleaning iCloud container Trash contents..."
    
      find "$HOME/Library/Mobile Documents" -type d -name ".Trash" -print0 2>/dev/null |
      while read -lz trash_dir
        echo "Found Trash: $trash_dir"
    
        find "$trash_dir" -mindepth 1 -maxdepth 1 -print0 |
        while read -lz target
          __ftrash_delete_one "$target"; or return 1
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


    # ---------------------------------------------------------
    # ---- vfix ---- #
    # Commit Vaultwarden reload changes
    # Remove old Vaultwarden and Nginx launch daemon plists
    # Run darwin-rebuild switch afterwards
    #
    # Example:
    # vfix
    # ---------------------------------------------------------
    vfix = ''
      gaa "Reloading Vaultwarden"

      # Vaultwarden
      sudo -H launchctl bootout system/com.ven.vaultwarden 2>/dev/null; or true
      sudo -H rm -f /Library/LaunchDaemons/com.ven.vaultwarden.plist

      # Nginx
      sudo -H launchctl bootout system/com.ven.nginx-custom 2>/dev/null; or true
      sudo -H rm -f /Library/LaunchDaemons/com.ven.nginx-custom.plist

      drs
    '';
    # ---------------------------------------------------------
  };
}