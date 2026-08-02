# darwin/terminal/aliases/quick-actions.nix
#
# =====================================================================
# QUICK ACTIONS
# 
# Custom reusable Fish actions
# =====================================================================

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
      # Set up paths for HOME, iCloud Drive, Application Support, and Preferences
      set home_path "$HOME"
      set mobile_docs "$HOME/Library/Mobile Documents"
      set icloud_drive "$mobile_docs/com~apple~CloudDocs"
      set app_support "$HOME/Library/Application Support"
      set preferences "$HOME/Library/Preferences"

      # Set for hidden files to be shown or not
      set show_hidden "no"

      # Initialize current kind and path
      set current_kind "root"
      set current_path "$home_path"

      # Initialize stacks for navigation history
      set stack_kind
      set stack_path

      
      # ------ HELPER FUNCTIONS ------ #
      function __cdf_pretty_container_name

      	# Convert iCloud container folder names to a more readable format
        set raw (basename "$argv[1]")
        set clean "$raw"

        # Remove common prefixes from iCloud container names
        set clean (string replace -r '^iCloud~' "" "$clean")
        set clean (string replace -r '^[A-Z0-9]+~' "" "$clean")
        set clean (string replace -r '^com~apple~' "" "$clean")

        # Split the cleaned name by '~' and take the last part for display
        set parts (string split "~" "$clean")
        set label "$parts[-1]"
    
        echo "$label"
      end

      # ------ ADD ROW FUNCTION ------ #
      function __cdf_add_row

      	# Add a row to the fzf menu with name, path, and kind
        printf "%s\t%s\t%s\n" "$argv[1]" "$argv[2]" "$argv[3]"
      end

      # ----- SKIP HIDDEN FILES FUNCTION ------ #
      function __cdf_should_skip_hidden
        set base (basename "$argv[1]")

        # If hidden files are not to be shown, skip them
        if test "$show_hidden" = "no"
          if string match -q ".*" "$base"
            return 0
          end
        end
    
        return 1
      end

      # ------ MAIN LOOP ------ #
      while true
      	# Set up an empty list of rows
        set rows

        # Populate the menu rows based on the current kind of folder
        switch "$current_kind"
          case root
          	# Populate the root menu with Home, iCloud, Application Support, Preferences, and a toggle for hidden files
            set -a rows (__cdf_add_row "Home" "$home_path" "folder")
            set -a rows (__cdf_add_row "iCloud" "$mobile_docs" "icloud-menu")
            set -a rows (__cdf_add_row "Application Support" "$app_support" "folder")
            set -a rows (__cdf_add_row "Preferences" "$preferences" "folder")
            set -a rows (__cdf_add_row "Show Hidden Files: $show_hidden" "$current_path" "toggle-hidden")

          # ------ MENU ROW FOR ALL ICLOUD APP CONTAINER FOLDERS ------ #
          case icloud-menu
          	# Add options for All Folders and App Containers in iCloud
            set -a rows (__cdf_add_row "All Folders" "$mobile_docs" "icloud-all")
            # Add option for App Containers in iCloud
            set -a rows (__cdf_add_row "App Containers" "$mobile_docs" "icloud-containers")

            # Add a toggle for showing hidden files in iCloud
			set -a rows (__cdf_add_row "Show Hidden Files: $show_hidden" "$current_path" "toggle-hidden")

          # ------ MENU ROW FOR ICLOUD ALL FOLDERS ------ #
          case icloud-all
          	# Add all folders in iCloud Drive to the menu
            if test -d "$icloud_drive"
              for dir in (find "$icloud_drive" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                # Set the display name for the folder and add it to the rows
                set name (basename "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end

            # ------ ADD ICLOUD CONTAINER FOLDERS TO THE MENU ------ #
            if test -d "$mobile_docs"
              # Add all iCloud container folders to the menu, skipping the main CloudDocs folder
              for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
              	# Skip hidden folders and the main CloudDocs folder
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                # Set the display name for the iCloud container folder and add it to the rows
                set base (basename "$dir")

                # Skip the main CloudDocs folder
                if test "$base" = "com~apple~CloudDocs"
                  continue
                end

                # Set the display name for the iCloud container folder and add it to the rows
                set name (__cdf_pretty_container_name "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end

          # ------ ADD ICLOUD CONTAINER FOLDERS TO THE MENU ------ #
          case icloud-containers
          	# For 'mobile_docs' directory, find all subdirectories (iCloud containers) and add them to the menu
            if test -d "$mobile_docs"
            
              # Loop through each subdirectory in 'mobile_docs', skipping hidden folders and the main CloudDocs folder
              for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                # Set the display name for the folder and add it to the rows
                set base (basename "$dir")

                # Skip the main CloudDocs folder
                if test "$base" = "com~apple~CloudDocs"
                  continue
                end

                # Set the display name for the iCloud container folder and add it to the rows
                set name (__cdf_pretty_container_name "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end


          # ------ FOR CURRENT_PATH FOLDER, ADD SUBFOLDERS TO THE MENU ------ #
          case folder
          
          	# For the current folder, find all subdirectories and add them to the menu, skipping hidden folders
            if test -d "$current_path"
              for dir in (find "$current_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                # Set the display name for the folder and add it to the rows
                set name (basename "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end
        end

        # Set the prompt name for fzf based on the current path
        set prompt_name (basename "$current_path")

        # Create the fzf menu with the rows and handle user selection
        set result (
          printf "%s\n" $rows |
          fzf \
          	# Set the header to show the current path
            --header="cdf: $current_path" \

            # Set the height of the fzf menu
            --height=80% \

            # Set the layout to reverse list for better visibility
            --layout=reverse-list \

            # Set the prompt to show the current folder name
            --prompt="$prompt_name > " \

            # Set the delimiter to tab for splitting the selected row into fields
            --delimiter=(printf "\t") \

            # Set the number of fields to expect in the selected row
            --with-nth=1 \

            # Set the expected keys for navigation and selection
            --expect=enter,right,left,ctrl-l,ctrl-h \

            # Set the preview command to show the contents of the selected folder using eza, if it exists
            --preview='test -d {2:q} && eza -la --icons=always {2:q} 2>/dev/null || true'
        )

        # If no selection was made, exit the function
        if test (count $result) -eq 0
          return 0
        end

        # Set the selected key, row, and fields based on the user's selection
        set key $result[1]
        set row $result[2]

        # If the selected row is empty, continue to the next iteration of the loop
        if test -z "$row"
          continue
        end

        # Split the selected row into fields using tab as the delimiter
        set fields (string split (printf "\t") "$row")
        set selected_name "$fields[1]"
        set selected_path "$fields[2]"
        set selected_kind "$fields[3]"

        # Handle the case where the user selected the "toggle-hidden" option to show or hide hidden files
        if test "$selected_kind" = "toggle-hidden"
          read -l -P "Show hidden files? [y/N]: " answer

          # If the user answered "y" or "yes", set show_hidden to "yes", otherwise set it to "no"
          if string match -qi "y" "$answer"; or string match -qi "yes" "$answer"
            set show_hidden "yes"
          else
            set show_hidden "no"
          end
    
          continue
        end

        # Handle the user's selection based on the key pressed (enter, right, left, ctrl-l, ctrl-h)
        switch "$key"
          case enter
            if test "$selected_kind" = "folder"
              builtin cd "$selected_path"
              return 0
            else
              # Set the stack to the current kind
              set -a stack_kind "$current_kind"

              # Set the stack to the current path
              set -a stack_path "$current_path"

              # Set the current kind to the selected kind
              set current_kind "$selected_kind"

              # Set the current path to the selected path
              set current_path "$selected_path"
            end

          # For set stack kind, push the current kind onto the stack and set the current kind and path to the selected kind and path
            set -a stack_kind "$current_kind"
            set -a stack_path "$current_path"

            # Set the current kind and path to the selected kind and path
            set current_kind "$selected_kind"
            set current_path "$selected_path"

          # For left ctrl-h, pop the last kind and path from the stack and set them as the current kind and path
          case left ctrl-h
            if test (count $stack_kind) -gt 0		# checks if the stack is not empty
              set current_kind "$stack_kind[-1]"
              set current_path "$stack_path[-1]"

              # Remove the last element from the stack_kind array
              # ** '-e' stands for 'erase', which removes the last element from the stack
              # ** 'set -e' is used to remove the last element from the stack after it has been popped
              set -e stack_kind[-1]
              set -e stack_path[-1]
              
            else
            	
              # Set the current kind and path to root if the stack is empty
              set current_kind "root"
              set current_path "$home_path"
            end
        end
      end
    '';
    # ---------------------------------------------------------


    
    
    # ---------------------------------------------------------
    # ---- trash -> Move files or folders to macOS Trash ---- #
    #
    # By default, asks Finder to move items to Trash.
    #
    # If Finder refuses:
    #   trash --force <path>
    #
    # permanently removes the item with rm -rf.
    #
    # Examples:
    # trash ./old-folder
    # trash "./file with spaces.zip"
    # trash ./folder-one ./folder-two
    # trash --force ./problem-folder
    # trash -- --filename-starting-with-dash
    # ---------------------------------------------------------
    
    trash = {
      description = "Move files to macOS Trash, or permanently remove them with --force";
    
      body = ''
        argparse 'f/force' -- $argv
        or begin
          echo "Usage: trash [-f|--force] <path> [path ...]"
          return 2
        end
    
        if test (count $argv) -eq 0
          echo "Usage: trash [-f|--force] <path> [path ...]"
          return 1
        end
    
        set -l failed 0
    
        for item in $argv
          # Include symbolic links, including broken ones.
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
    
          # Convert the POSIX path before asking Finder to delete it.
          osascript \
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
    
          # Do not permanently remove anything unless --force was supplied.
          if not set -q _flag_force
            echo "Could not move to Trash: $target"
            echo "Use --force to remove it permanently:"
            echo "  trash --force \"$target\""
            set failed 1
            continue
          end
    
          # Basic protection against catastrophic typos.
          switch "$target"
            case / "$HOME" /Users /System /Library /Applications
              echo "Refusing to permanently remove protected path: $target"
              set failed 1
              continue
          end
    
          echo "Finder failed; permanently removing: $target"
    
          command rm -rf -- "$target"
    
          if test $status -eq 0
            echo "Permanently removed: $target"
          else
            echo "Could not permanently remove: $target"
            set failed 1
          end
        end
    
        return $failed
      '';
    };
    # ---------------------------------------------------------
 
    
    # ---------------------------------------------------------
    # ---- archive_clean_folder -> Clean and archive folder ---- #
    # Downloads all iCloud files, removes common junk files,
    # creates and verifies a zip, then deletes the source folder
    #
    # Usage:
    # archive_clean_folder <source> <destination> [required_suffix]
    #
    # Example:
    # archive_clean_folder ./Gruvbox ~/.config/theme-archives "-theme"
    # ---------------------------------------------------------
    archive_clean_folder = ''
      set source "$argv[1]"
      set destination "$argv[2]"
      set required_suffix "$argv[3]"

      if test -z "$source"; or test -z "$destination"
        echo "Usage:"
        echo "  archive_clean_folder <source> <destination> [required_suffix]"
        return 1
      end

      if not test -d "$source"
        echo "Missing folder: $source"
        return 1
      end

      mkdir -p "$destination"; or begin
        echo "Could not create destination: $destination"
        return 1
      end

      set folder_name (basename "$source")
      set archive_base "$folder_name"

      if test -n "$required_suffix"
        if not string match -q -- "*$required_suffix" "$folder_name"
          set archive_base "$folder_name$required_suffix"
        end
      end

      set archive_name "$archive_base.zip"
      set final_archive "$destination/$archive_name"

      set work_dir (mktemp -d -t theme-archive); or begin
        echo "Could not create temporary working directory."
        return 1
      end

      set staged_folder "$work_dir/$folder_name"
      set temporary_archive "$work_dir/$archive_name"

      echo
      echo "Processing: $source"
      echo "Requesting all files from iCloud..."

      if command -q brctl
        brctl download "$source" >/dev/null 2>&1

        find "$source" -type f -print0 2>/dev/null |
        while read -lz file
          brctl download "$file" >/dev/null 2>&1
        end
      end

      echo "Checking that every file can be read..."

      set unreadable_files

      find "$source" -type f -print0 2>/dev/null |
      while read -lz file
        command dd \
          if="$file" \
          of=/dev/null \
          bs=1048576 \
          status=none 2>/dev/null

        if test $status -ne 0
          set -a unreadable_files "$file"
        end
      end

      if test (count $unreadable_files) -gt 0
        echo
        echo "These files could not be downloaded or read:"

        for file in $unreadable_files
          echo "  $file"
        end

        echo
        echo "Archive cancelled. The original folder was not changed."

        rm -rf -- "$work_dir"
        return 1
      end

      echo "Copying folder to temporary workspace..."

      ditto "$source" "$staged_folder"; or begin
        echo "Copy failed: $source"
        echo "The original folder was not changed."

        rm -rf -- "$work_dir"
        return 1
      end

      # macOS, Finder, Windows and filesystem metadata junk.
      find "$staged_folder" -depth \( \
        -name ".DS_Store" -o \
        -name ".AppleDouble" -o \
        -name ".LSOverride" -o \
        -name (printf 'Icon\r') -o \
        -name "._*" -o \
        -name "__MACOSX" -o \
        -name ".Spotlight-V100" -o \
        -name ".Trashes" -o \
        -name ".fseventsd" -o \
        -name ".TemporaryItems" -o \
        -name ".DocumentRevisions-V100" -o \
        -name "Thumbs.db" -o \
        -name "ehthumbs.db" -o \
        -name "desktop.ini" \
      \) -exec rm -rf -- {} +

      # Git and GitHub repository junk.
      find "$staged_folder" -depth \( \
        -name ".git" -o \
        -name ".github" -o \
        -name ".gitignore" -o \
        -name ".gitattributes" -o \
        -name ".gitmodules" \
      \) -exec rm -rf -- {} +

      # Documentation and legal files or folders, case-insensitively.
      for junk_name in \
        author authors \
        contribution contributions \
        copyright copyrights \
        credit credits \
        gpl \
        license licenses \
        log \
        nfo

        find "$staged_folder" -depth \( \
          -iname "$junk_name" -o \
          -iname "$junk_name.txt" -o \
          -iname "$junk_name.md" -o \
          -iname "$junk_name.log" \
        \) -exec rm -rf -- {} +
      end

      set previous_directory "$PWD"

      cd "$work_dir"; or begin
        echo "Could not enter temporary working directory."

        rm -rf -- "$work_dir"
        return 1
      end

      command zip -qry "$temporary_archive" "$folder_name"
      set zip_status $status

      cd "$previous_directory"; or begin
        echo "Could not return to: $previous_directory"

        rm -rf -- "$work_dir"
        return 1
      end

      if test $zip_status -ne 0
        echo "Archive creation failed: $archive_name"
        echo "The original folder was not changed."

        rm -rf -- "$work_dir"
        return 1
      end

      command unzip -tq "$temporary_archive" >/dev/null 2>&1

      if test $status -ne 0
        echo "Archive verification failed: $archive_name"
        echo "The original folder was not changed."

        rm -rf -- "$work_dir"
        return 1
      end

      if test -e "$final_archive"
        echo "An archive already exists:"
        echo "$final_archive"
        echo
        echo "The existing archive was not replaced."
        echo "The original folder was not changed."

        rm -rf -- "$work_dir"
        return 1
      end

      mv -fv "$temporary_archive" "$final_archive"; or begin
        echo "Could not move archive to:"
        echo "$destination"
        echo
        echo "The original folder was not changed."

        rm -rf -- "$work_dir"
        return 1
      end

      if not test -s "$final_archive"
        echo "Final archive is missing or empty:"
        echo "$final_archive"
        echo
        echo "The original folder was not changed."

        rm -f -- "$final_archive"
        rm -rf -- "$work_dir"
        return 1
      end

      command unzip -tq "$final_archive" >/dev/null 2>&1

      if test $status -ne 0
        echo "Final archive verification failed:"
        echo "$final_archive"
        echo
        echo "The original folder was not changed."

        rm -f -- "$final_archive"
        rm -rf -- "$work_dir"
        return 1
      end

      rm -rf -- "$source"; or begin
        echo "Archive succeeded, but source deletion failed:"
        echo "$source"

        rm -rf -- "$work_dir"
        return 1
      end

      rm -rf -- "$work_dir"

      echo "Completed: $final_archive"
    '';
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # ---- sscript -> chmod script file or scripts in folder ---- #
    # Makes one script executable, or all scripts in a folder
    # ---------------------------------------------------------
    sscript = ''

      # Check if any arguments were provided; if not, display usage instructions and return an error
      if test (count $argv) -eq 0

      	# Display usage instructions for the sscript function
        echo "Usage:"
        
        # Display usage for making a single script file executable
        echo "  sscript <script-file>"

        # Display usage for making all scripts in a folder executable
        echo "  sscript <folder>"

        # Return an error code indicating that the function was called incorrectly
        return 1
      end

      # Combine all provided arguments into a single string to form the target path
      set target (string join " " $argv)

      # ---- HELPER FUNCTION FOR CHMOD ---- #

      # Helper function to make a file executable if it is a recognized script
      function __sscript_chmod_file

      	# Get the file path from the first argument and determine its extension
        set file "$argv[1]"

        # Determine the file extension in lowercase for comparison
        set ext (string lower (path extension "$file"))


        # Check if the file extension matches common script extensions; if so, make it executable and print a message
        if contains "$ext" .py .sh .bash .zsh .fish .command
          chmod +x "$file"
          echo "Executable: $file"
          return 0
        end


        # Check if the first line of the file starts with a shebang (#!); if so, make it executable and print a message
        if head -n 1 "$file" 2>/dev/null | string match -q '#!*'
          chmod +x "$file"
          echo "Executable: $file"
          return 0
        end

        return 1
      end

      # ---- MAIN LOGIC ---- #

      # Check if the target is a file; if so, attempt to make it executable using the helper function and print a message
      if test -f "$target"
        __sscript_chmod_file "$target"; or echo "Skipped, not detected as script: $target"
        return 0
      end

      # Check if the target is a directory; if so, find all files in the directory and attempt to make them executable using the helper function
      if test -d "$target"
        find "$target" -maxdepth 1 -type f -print0 |
        while read -lz file
          __sscript_chmod_file "$file"
        end

        return 0
      end

      # If the target is neither a file nor a directory, print an error message and return an error code
      echo "Not found: $target"
      return 1
    '';
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # ---- appqu -> Remove quarantine attributes from app(s) ---- #
    # Command for removing quarantine attributes from
    # one or more apps or files
    # ---------------------------------------------------------

    # Define the appqu function with a description for removing quarantine attributes from one or more apps/files
    appqu = {
      description = "Remove quarantine attributes from one or more apps/files";

      body = ''
      	# Check if any arguments were provided; if not, display usage instructions and return an error
        if test (count $argv) -eq 0

        	# Display usage instructions for the appqu function
          echo "Usage: appqu <path> [path ...]"

          # Return an error code indicating that the function was called incorrectly
          return 1
        end


        # Loop through each provided path and remove quarantine attributes using the xattr command
        for path in $argv

        	# Print a message indicating the path being processed
          echo "Removing quarantine: $path"

          # Use the xattr command to recursively remove quarantine attributes from the specified path
          xattr -cr "$path"
        end
      '';
    };
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # ---- icloudfix -> Restart iCloud/FileProvider services ---- #
    # Restarts Finder and iCloud-related daemons when iCloud
    # folders or app containers stop appearing correctly
    #
    # Example:
    # icloudfix
    # ---------------------------------------------------------
    icloudfix = ''
      echo "Restarting iCloud/FileProvider services..."

      # Kill Finder and iCloud-related daemons to force a restart of the services
      killall Finder 2>/dev/null; or true
      killall fileproviderd 2>/dev/null; or true
      killall bird 2>/dev/null; or true
      killall cloudd 2>/dev/null; or true

      # Set the sleep duration to allow the services to restart properly
      sleep 3

      # Open the iCloud Mobile Documents folder in Finder to verify that the folders are now visible
      open ~/Library/Mobile\ Documents

      # Print a message indicating that the process is complete and suggest rebooting if iCloud folders are still missing
      echo "Done. If iCloud folders are still missing, reboot once."
    '';
    # ---------------------------------------------------------
    
    
    # ---------------------------------------------------------
    # ---- ia -> Internet Archive helper through Python ---- #
    # Download Internet Archive files by type
    #
    # Examples:
    # ia dll https://archive.org/details/NARA-26300439
    # ia dll pdf https://archive.org/details/NARA-26300439
    # ia dll epub https://archive.org/details/NARA-26300439
    # ---------------------------------------------------------
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
    # ---------------------------------------------------------
  };
}