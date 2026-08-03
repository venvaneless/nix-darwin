# darwin/terminal/commands/trash.nix
#
# =====================================================================
# FISH FUNCTIONS: TRASH
#
# Trash-related commands
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
  # -----------------------------------------------------------------
    # ---- sys-trash -> Trash manager with fzf ---- #
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
    # sys-trash
    # -----------------------------------------------------------------
    sys-trash = ''

      # Define the system Trash directory path
      set system_trash "$HOME/.Trash"

      # Define the iCloud root directory path
      set icloud_root "$HOME/Library/Mobile Documents"

      # Define a helper function to clean a specified trash directory
      function __sys-trash_clean_dir

      	# Set the trash directory to clean from the first argument
        set trash_dir "$argv[1]"

        # Check if the trash directory exists
        if not test -d "$trash_dir"

          # If it doesn't, print a message indicating that the trash directory was not found and return success
          echo "Trash not found: $trash_dir"
          return 0
        end

        
        # Delete all items in the trash directory
        # ---------------------------------------------------------------
        # ** NOTE:
        # ** 'mindepth 1' ensures that only the contents of the trash directory are deleted, not the directory itself
        # ** 'maxdepth 1' ensures that only the immediate contents of the trash directory are deleted, not any nested directories
        # ** 'print0' outputs the file names followed by a null character, which is useful for handling file names with spaces or special characters
        # ---------------------------------------------------------------
        find "$trash_dir" -mindepth 1 -maxdepth 1 -print0 |

        # While loop to read each target item in the trash directory
        while read -lz target

          # Print a message indicating that the target is being deleted
          echo "Deleting: $target"

          # Remove macOS file flags that can block deletion
          # ---------------------------------------------------------------
          # ** NOTE:
          # 'chflags -R nouchg,noschg' removes the 'uchg' (user immutable) and 'schg' (system immutable) flags recursively from the target
          # ** '2>/dev/null' redirects any error messages to /dev/null, effectively silencing them
          # ** 'chflags' stands for "change flags" and is used to modify file attributes on macOS
          # ** '-R' flag stands for "recursive", meaning it will apply the changes to the target and all its contents
          # ** 'nouchg' flag removes the user immutable flag, allowing the file to be modified or deleted
          # ** 'noschg' flag removes the system immutable flag, allowing the file to be modified or deleted
          # ---------------------------------------------------------------
          chflags -R nouchg,noschg "$target" 2>/dev/null; or true

          # Remove extended attributes that can confuse iCloud/Finder
          xattr -cr "$target" 2>/dev/null; or true

          # Delete the target item from the trash directory
          rm -rf "$target" 2>/dev/null; or true
        end
      end

      
      # ---- FZF MENU FOR TRASH MANAGEMENT ---- #
      set choice (
      	# Use printf to create a list of options for the user to choose from
      	# Each option corresponds to a specific action related to managing the system Trash or iCloud Trash
        # Option to view the contents of the system Trash
        # Option to clean (delete all contents of) the system Trash
        # Option to view the contents of the iCloud Trash
        # Option to clean (delete all contents of) the iCloud Trash
        # Pipe the list of options to fzf for interactive selection
        printf "%s\n" \
          "System Trash / View Trash" \
          "System Trash / Clean Trash" \
          "iCloud Trash / View Trash" \
          "iCloud Trash / Clean Trash" |
        fzf --height=40% --reverse --prompt="trash> "
      )

      
      # ---- USER'S CHOICE HANDLING ---- #
      switch "$choice"

      	# Handle the user's choice for viewing the system Trash
        case "System Trash / View Trash"

          # Set eza to always show icons and list the contents of the system Trash directory
          eza -la --icons=always "$system_trash"


        # Handle the user's choice for cleaning the system Trash
        case "System Trash / Clean Trash"
          __sys-trash_clean_dir "$system_trash"



        # Handle the user's choice for viewing the iCloud Trash
        case "iCloud Trash / View Trash"

          # Find all .Trash directories within the iCloud root and list their contents
          find "$icloud_root" -type d -name ".Trash" -print0 2>/dev/null |

          
          # While loop to read each found .Trash directory and display its contents
          while read -lz trash_dir
            echo
            echo "Trash: $trash_dir"

            # List the contents of the found .Trash directory using eza with icons
            eza -la --icons=always "$trash_dir"
          end


        # Handle the user's choice for cleaning the iCloud Trash          
        case "iCloud Trash / Clean Trash"

          # Find all .Trash directories within the iCloud root and clean their contents
          find "$icloud_root" -type d -name ".Trash" -print0 2>/dev/null |

          # While loop to read each found .Trash directory and clean its contents
          while read -lz trash_dir

            # Print a message indicating which iCloud Trash directory is being cleaned
            echo "Cleaning: $trash_dir"

            # Call the helper function to clean the contents of the found .Trash directory
            __sys-trash_clean_dir "$trash_dir"
          end
      end
    '';
    # -----------------------------------------------------------------


    # -----------------------------------------------------------------
    # ---- trash -> Trash, permanently delete, or empty Trash ---- #
    #
    # Examples:
    # trash ./old-folder
    # trash "./file with spaces.zip"
    # trash --permanent ./old-folder
    # trash --stubborn ./stuck-icloud-folder
    # trash --empty
    # -----------------------------------------------------------------
    trash = {
      description = "Move items to Trash, permanently remove them, or empty macOS Trash";

      body = ''
        argparse \
          'h/help' \
          'p/permanent' \
          's/stubborn' \
          'e/empty' \
          -- $argv
        or begin
          echo "Usage:"
          echo "  trash <path> [path ...]"
          echo "  trash --permanent <path> [path ...]"
          echo "  trash --stubborn <path> [path ...]"
          echo "  trash --empty"
          return 2
        end

        if set -q _flag_help
          echo "Usage:"
          echo "  trash <path> [path ...]"
          echo "  trash --permanent <path> [path ...]"
          echo "  trash --stubborn <path> [path ...]"
          echo "  trash --empty"
          echo ""
          echo "Modes:"
          echo "  No option     Move items to macOS Trash."
          echo "  --permanent   Permanently remove items after confirmation."
          echo "  --stubborn    Clear flags and extended attributes before permanent removal."
          echo "                 Offers to retry with sudo if normal removal fails."
          echo "  --empty       Ask Finder to permanently empty macOS Trash."
          return 0
        end

        set -l selected_modes

        if set -q _flag_permanent
          set -a selected_modes permanent
        end

        if set -q _flag_stubborn
          set -a selected_modes stubborn
        end

        if set -q _flag_empty
          set -a selected_modes empty
        end

        if test (count $selected_modes) -gt 1
          echo "Use only one of:"
          echo "  --permanent"
          echo "  --stubborn"
          echo "  --empty"
          return 2
        end

        set -l mode trash

        if test (count $selected_modes) -eq 1
          set mode $selected_modes[1]
        end

        if test "$mode" = empty
          if test (count $argv) -ne 0
            echo "trash --empty does not accept paths."
            return 2
          end

          read -l -P "Permanently empty macOS Trash? [y/N] " confirmation

          if not string match -rqi '^(y|yes)$' -- "$confirmation"
            echo "Trash was not emptied."
            return 0
          end

          /usr/bin/osascript \
            -e 'tell application "Finder" to empty trash'

          if test $status -eq 0
            echo "Emptied macOS Trash."
            return 0
          end

          echo "Finder could not empty macOS Trash."
          echo "Nothing outside Finder was deleted."
          return 1
        end

        if test (count $argv) -eq 0
          echo "Usage:"
          echo "  trash <path> [path ...]"
          echo "  trash --permanent <path> [path ...]"
          echo "  trash --stubborn <path> [path ...]"
          echo "  trash --empty"
          return 1
        end

        set -l failed 0

        for item in $argv
          # Include symbolic links, including broken symbolic links.
          if not test -e "$item"; and not test -L "$item"
            echo "Not found: $item"
            set failed 1
            continue
          end

          # Produce an absolute path without resolving symbolic links.
          if string match -q '/*' -- "$item"
            set target (path normalize -- "$item")
          else
            set target (path normalize -- "$PWD/$item")
          end

          # Protect important filesystem and user-data roots.
          switch "$target"
            case \
              / \
              /Applications \
              /Library \
              /System \
              /Users \
              /Volumes \
              /bin \
              /dev \
              /etc \
              /opt \
              /private \
              /sbin \
              /tmp \
              /usr \
              /var \
              "$HOME" \
              "$HOME/.Trash" \
              "$HOME/Library" \
              "$HOME/Library/Mobile Documents" \
              "$HOME/Library/Mobile Documents/com~apple~CloudDocs" \
              "$HOME/Library/Containers" \
              "$HOME/Library/Group Containers"

              echo "Refusing to remove protected path: $target"
              set failed 1
              continue
          end

          switch "$mode"
            case permanent
              read -l -P "Permanently remove '$target'? [y/N] " confirmation

              if not string match -rqi '^(y|yes)$' -- "$confirmation"
                echo "Skipped: $target"
                continue
              end

              # Remove only a direct user-immutable flag.
              # Use --stubborn if flags exist inside the directory tree.
              chflags nouchg "$target" 2>/dev/null; or true

              command rm -rf -- "$target"

              if not test -e "$target"; and not test -L "$target"
                echo "Permanently removed: $target"
              else
                echo "Could not permanently remove: $target"
                echo "For a more aggressive attempt, run:"
                echo "  trash --stubborn \"$target\""
                set failed 1
              end

            case stubborn
              echo "Stubborn deletion will:"
              echo "  - permanently remove the item"
              echo "  - recursively clear macOS file flags"
              echo "  - recursively clear extended attributes"
              echo "  - offer to retry with sudo if necessary"
              echo ""

              read -l -P "Aggressively remove '$target'? [y/N] " confirmation

              if not string match -rqi '^(y|yes)$' -- "$confirmation"
                echo "Skipped: $target"
                continue
              end

              chflags -R nouchg,noschg "$target" 2>/dev/null; or true
              xattr -cr "$target" 2>/dev/null; or true

              command rm -rf -- "$target" 2>/dev/null

              if not test -e "$target"; and not test -L "$target"
                echo "Permanently removed: $target"
                continue
              end

              echo "Normal deletion failed."

              read -l -P "Retry '$target' with sudo? [y/N] " sudo_confirmation

              if not string match -rqi '^(y|yes)$' -- "$sudo_confirmation"
                echo "Could not permanently remove: $target"
                set failed 1
                continue
              end

              sudo chflags -R nouchg,noschg "$target" 2>/dev/null; or true
              sudo xattr -cr "$target" 2>/dev/null; or true
              sudo /bin/rm -rf -- "$target" 2>/dev/null

              if not test -e "$target"; and not test -L "$target"
                echo "Permanently removed with sudo: $target"
              else
                echo "Could not permanently remove: $target"
                set failed 1
              end

            case trash
              # Remove only a direct user-immutable flag before trashing.
              chflags nouchg "$target" 2>/dev/null; or true

              # Try macOS's Trash utility first.
              /usr/bin/trash "$target"
              set -l trash_status $status

              if test $trash_status -eq 0
                echo "Moved to Trash: $target"
                continue
              end

              # Fall back to Finder for iCloud-managed items.
              /usr/bin/osascript \
                -e 'on run argv' \
                -e 'set targetItem to POSIX file (item 1 of argv) as alias' \
                -e 'tell application "Finder" to delete targetItem' \
                -e 'end run' \
                "$target"

              set -l finder_status $status

              if test $finder_status -eq 0
                echo "Moved to Trash: $target"
                continue
              end

              # Never permanently delete after an unsuccessful Trash attempt.
              echo "Could not move to Trash: $target"
              echo "It was not permanently removed."
              echo ""
              echo "For normal permanent deletion, run:"
              echo "  trash --permanent \"$target\""
              echo ""
              echo "For a stubborn iCloud item, run:"
              echo "  trash --stubborn \"$target\""
              set failed 1
          end
        end

        return $failed
      '';
    };
    # -----------------------------------------------------------------
  };
}
