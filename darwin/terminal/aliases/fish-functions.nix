# darwin/terminal/aliases/fish-functions.nix
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
      # Check if zoxide is installed
      set selected_path (

      	# Use zoxide to list tracked paths and pipe to fzf for selection
        zoxide query -l |

        # Set fzf options for height, reverse order, and prompt
        fzf --height=60% --reverse --prompt="zoxide cd> "
      )

      # If no path is selected, exit the function
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

      # Remove trailing slashes from the source path
      set -l src (string replace -r '/+$' "" -- "$argv[1]")

      # Check if the source path is provided and exists
      if test -z "$src"; or not test -e "$src"
      
      	# If not, print usage message and return an error code
        echo "Usage: backup <path/to/file/or/folder>"
        return 1
      end

      # Get the base name of the source path and create the output zip file path
      set -l name (basename "$src")
      set -l out "$PWD/$name.zip"

      # Check if the output zip file already exists
      if test -e "$out"
        echo "Backup already exists: $out"
        return 1
      end

      # Use ditto to create a zip archive of the source path
      /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$src" "$out"

      # Print a message indicating that the backup was created successfully
      echo "Created: $out"
    '';
    
  
    # ------------------------------------------------------------
    # Backup file/folder to timestamped zip
    # ------------------------------------------------------------
    backuptime = ''

      # Remove trailing slashes from the source path
      set -l src (string replace -r '/+$' "" -- "$argv[1]")

      # Check if the source path is provided and exists
      if test -z "$src"; or not test -e "$src"
        echo "Usage: backuptime <path/to/file/or/folder>"
        return 1
      end

      # Get the base name of the source path and create a timestamped output zip file path
      set -l name (basename "$src")
      set -l stamp (date "+%Y%m%d-%H%M")
      set -l out "$PWD/$stamp-$name.zip"

      # Check if the output zip file already exists
      if test -e "$out"
        echo "Backup already exists: $out"
        return 1
      end

      # Use ditto to create a zip archive of the source path with a timestamp
      /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$src" "$out"

      # Print a message indicating that the backup was created successfully
      echo "Created: $out"
    '';
    # ---------------------------------------------------------

    
    # ------------------------------------------------------------
    # Copy file/folder to explicit destination path
    # ------------------------------------------------------------
    copyf = ''

      # Remove trailing slashes from the source and destination paths
      set -l src (string replace -r '/+$' "" -- "$argv[1]")

      # Remove trailing slashes from the destination path
      set -l dest (string replace -r '/+$' "" -- "$argv[2]")

      
      # Check if the source and destination paths are provided and if the source exists
      if test -z "$src"; or test -z "$dest"; or not test -e "$src"

      	# If not, print usage message and return an error code
        echo "Usage: copyf <path/to/file/or/folder> <destination/path>"

        # Return an error code indicating failure
        return 1
      end


      # Check if the destination path already exists
      if test -e "$dest"

      	# If it does, print a message indicating that the destination already exists and return an error code
        echo "Destination already exists: $dest"

        # Return an error code indicating failure
        return 1
      end

      # Create the destination directory if it doesn't exist and copy the source to the destination
      mkdir -p (dirname "$dest")
      /usr/bin/ditto "$src" "$dest"

      # Print a message indicating that the copy operation was successful
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

      # Define the system Trash directory path
      set system_trash "$HOME/.Trash"

      # Define the iCloud root directory path
      set icloud_root "$HOME/Library/Mobile Documents"



      # Define a helper function to clean a specified trash directory
      function __ftrash_clean_dir

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
        printf "%s\n" \
      	# Each option corresponds to a specific action related to managing the system Trash or iCloud Trash

          # Option to view the contents of the system Trash
          "System Trash / View Trash" \

          # Option to clean (delete all contents of) the system Trash
          "System Trash / Clean Trash" \

          # Option to view the contents of the iCloud Trash
          "iCloud Trash / View Trash" \

          # Option to clean (delete all contents of) the iCloud Trash
          "iCloud Trash / Clean Trash" |

        # Pipe the list of options to fzf for interactive selection
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
          __ftrash_clean_dir "$system_trash"



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

          Find all .Trash directories within the iCloud root and clean their contents
          find "$icloud_root" -type d -name ".Trash" -print0 2>/dev/null |

          # While loop to read each found .Trash directory and clean its contents
          while read -lz trash_dir

            # Print a message indicating which iCloud Trash directory is being cleaned
            echo "Cleaning: $trash_dir"

            # Call the helper function to clean the contents of the found .Trash directory
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

      # Check if any arguments were provided; if not, print usage message and return an error code
      if test (count $argv) -eq 0

        # Print usage message to inform the user how to use the dtrash function
        echo "Usage: dtrash <path> [path...]"

        # Return an error code indicating failure
        return 1
      end


      # Loop through each target path provided as an argument
      for target in $argv

      	# Check if the target path exists;
        if not test -e "$target"

          # If it doesn't, print a message indicating that the target was not found and continue to the next iteration of the loop
          echo "Not found: $target"
          continue
        end


        # Print a message indicating that the target is being force deleted
        echo "Force deleting: $target"

        # Remove macOS file flags that can block deletion
        chflags -R nouchg,noschg "$target" 2>/dev/null; or true

        # Remove extended attributes that can confuse iCloud/Finder
        xattr -cr "$target" 2>/dev/null; or true

        # Delete the target
        rm -rf "$target"


        # Check if the target still exists after the initial deletion attempt
        if test -e "$target"
          echo "Normal delete failed, trying sudo..."
          
          # If the target still exists, attempt to force delete it using sudo
          sudo chflags -R nouchg,noschg "$target" 2>/dev/null; or true

          # Remove extended attributes again using sudo
          sudo xattr -cr "$target" 2>/dev/null; or true
          sudo rm -rf "$target"
        end


        # Final check to see if the target still exists after all deletion attempts
        if test -e "$target"
          echo "Failed to delete: $target"

          # If the target still exists, print a failure message and return an error code
          return 1

        # If the target was successfully deleted, print a success message
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
      # Define a helper function to force delete a single target
      function __strash_delete_one

        # Set the target to delete from the first argument
        set target "$argv[1]"


        # Check if the target exists; if not, print a message and return success
        if not test -e "$target"
          echo "Not found: $target"
          return 0
        end

        # Print a message indicating that the target is being force deleted
        echo "Force deleting: $target"


        # Remove macOS file flags that can block deletion
        chflags -R nouchg,noschg "$target" 2>/dev/null; or true

        # Remove extended attributes that can confuse iCloud/Finder
        xattr -cr "$target" 2>/dev/null; or true

        # Delete the target
        rm -rf "$target" 2>/dev/null


        # Check the target still exists after the initial deletion attempt
        if test -e "$target"

          # If the target still exists, print a message indicating that normal deletion failed and attempt to delete it using sudo
          echo "Normal delete failed, trying sudo..."

          # If the target still exists, attempt to force delete it using sudo with elevated privileges
          sudo chflags -R nouchg,noschg "$target" 2>/dev/null; or true

          # Remove extended attributes again using sudo
          sudo xattr -cr "$target" 2>/dev/null; or true

          # Delete the target using sudo
          sudo rm -rf "$target"
        end


        # Final check to see if the target still exists after all deletion attempts
        if test -e "$target"
          # If the target still exists, print a failure message and return an error code
          echo "Failed to delete: $target"

          # Return an error code indicating failure
          return 1

        # If the target was successfully deleted, print a success message
        else
          echo "Deleted: $target"
        end
      end


      # If any arguments were provided, loop through each target and force delete it
      if test (count $argv) -gt 0

      	# Loop through each target provided as an argument and call the helper function to force delete it
        for target in $argv
          __strash_delete_one "$target"; or return 1
        end
        return 0
      end

      
      # If no arguments were provided, clean both the system Trash and iCloud container Trash
      echo "Cleaning system Trash contents..."


      # Check if the system Trash directory exists; if it does, find all items in it and force delete them
      if test -d "$HOME/.Trash"

      	# Find all items in the system Trash and force delete them
        find "$HOME/.Trash" -mindepth 1 -maxdepth 1 -print0 |

        # Loop through each item in the system Trash and call the helper function to force delete it
        while read -lz target

          # Delete the target item from the system Trash or return an error code if it fails
          __strash_delete_one "$target"; or return 1
        end
      end

      # Print a message indicating that the iCloud container Trash contents are being cleaned
      echo "Cleaning iCloud container Trash contents..."


      # Find all .Trash directories within the iCloud container and force delete their contents 
      find "$HOME/Library/Mobile Documents" -type d -name ".Trash" -print0 2>/dev/null |

      # Read each found .Trash directory using the option to handle null-terminated strings and call the helper function to force delete its contents
      while read -lz trash_dir
        echo "Found Trash: $trash_dir"

        # Find all items in the found .Trash directory using the option to handle null-terminated strings and force delete them 
        # ** Set the minimum depth to 1 to avoid deleting the .Trash directory itself and the maximum depth to 1 to only delete immediate contents
        # ** Set the maximum depth to 1 to only delete immediate contents
        # ** Set print0 to output the file names followed by a null character, which is useful for handling file names with spaces or special characters
        find "$trash_dir" -mindepth 1 -maxdepth 1 -print0 |
        while read -lz target

          # Choose to delete the target item from the iCloud container Trash or return an error code if it fails
          __strash_delete_one "$target"; or return 1
        end
      end
    '';
    # ---------------------------------------------------------
  };
}