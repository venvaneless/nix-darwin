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
    # vfix
    # ---------------------------------------------------------
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
    # ---- gsd -> Git commit with timestamp + drs ---- #
    # Stage all repository changes
    # Create commit with appended timestamp:
    # yyyy-mm-dd hh:mm
    # Run darwin-rebuild switch afterwards
    #
    # Example:
    # gsd "Fixing nginx"
    # -> "Fixing nginx 2026-05-23 19:42"
    # ---------------------------------------------------------
    gsd = ''
      set timestamp (date "+%Y-%m-%d %H:%M")
      set message (string join " " $argv)

      gaa "$message $timestamp"
      and drs
    '';
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # ---- gm -> Stage all repo changes with drs ---- #
    # Create a git commit using the provided message
    # Run darwin-rebuild switch afterwards
    # ---------------------------------------------------------
    gm = ''
      git add -A
      and git commit -m "$argv"
      and drs
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
  };
}