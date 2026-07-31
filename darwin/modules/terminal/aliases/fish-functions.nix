# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/fish-functions.nix
#
# =====================================================================
# FISH FUNCTIONS
# 
# Custom reusable Fish shell functions
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
    # ---------- General Fish Functions ---------- #


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


    # ------------------------------------------------------------
    # Backup file/folder to zip
    # ------------------------------------------------------------
    backup = ''
      set -l src (string replace -r '/+$' "" -- "$argv[1]")
  
      if test -z "$src"; or not test -e "$src"
        echo "Usage: backup <path/to/file/or/folder>"
        return 1
      end
  
      set -l name (basename "$src")
      set -l out "$PWD/$name.zip"
  
      if test -e "$out"
        echo "Backup already exists: $out"
        return 1
      end
  
      /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$src" "$out"
  
      echo "Created: $out"
    '';
    
  
    # ------------------------------------------------------------
    # Backup file/folder to timestamped zip
    # ------------------------------------------------------------
    backuptime = ''
      set -l src (string replace -r '/+$' "" -- "$argv[1]")
  
      if test -z "$src"; or not test -e "$src"
        echo "Usage: backuptime <path/to/file/or/folder>"
        return 1
      end
  
      set -l name (basename "$src")
      set -l stamp (date "+%Y%m%d-%H%M")
      set -l out "$PWD/$stamp-$name.zip"
  
      if test -e "$out"
        echo "Backup already exists: $out"
        return 1
      end
  
      /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$src" "$out"
  
      echo "Created: $out"
    '';
    # ---------------------------------------------------------

    
    # ------------------------------------------------------------
    # Copy file/folder to explicit destination path
    # ------------------------------------------------------------
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
  
      mkdir -p (dirname "$dest")
      /usr/bin/ditto "$src" "$dest"
  
      echo "Copied: $src -> $dest"
    '';
    # ---------------------------------------------------------

  
    # ------------------------------------------------------------
    # Alias for copyf
    # ------------------------------------------------------------
    copyfolder = ''
      copyf $argv
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
  };
}