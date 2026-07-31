# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/quick-actions.nix
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
      if test (count $argv) -eq 0
        echo "Usage:"
        echo "  sscript <script-file>"
        echo "  sscript <folder>"
        return 1
      end

      set target (string join " " $argv)

      function __sscript_chmod_file
        set file "$argv[1]"
        set ext (string lower (path extension "$file"))

        if contains "$ext" .py .sh .bash .zsh .fish .command
          chmod +x "$file"
          echo "Executable: $file"
          return 0
        end

        if head -n 1 "$file" 2>/dev/null | string match -q '#!*'
          chmod +x "$file"
          echo "Executable: $file"
          return 0
        end

        return 1
      end

      if test -f "$target"
        __sscript_chmod_file "$target"; or echo "Skipped, not detected as script: $target"
        return 0
      end

      if test -d "$target"
        find "$target" -maxdepth 1 -type f -print0 |
        while read -lz file
          __sscript_chmod_file "$file"
        end

        return 0
      end

      echo "Not found: $target"
      return 1
    '';
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

      killall Finder 2>/dev/null; or true
      killall fileproviderd 2>/dev/null; or true
      killall bird 2>/dev/null; or true
      killall cloudd 2>/dev/null; or true

      sleep 3

      open ~/Library/Mobile\ Documents

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

          command ia download "$identifier" "--glob=*.$filetype"

        case '*'
        command ia $argv
      end
    '';
    # ---------------------------------------------------------
  };
}