# darwin/terminal/commands/backup.nix
#
# =====================================================================
# FISH FUNCTIONS: BACKUP
# 
# Functions and commands for quick backups of files and folders,
# including timestamped backups and copying to explicit destinations.
# =====================================================================

{ ... }:

{
  programs.fish.functions = {
  # -----------------------------------------------------------------
  # Backup file/folder to zip
  # -----------------------------------------------------------------
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
    # -----------------------------------------------------------------

  
    # -----------------------------------------------------------------
    # Backup file/folder to timestamped zip
    # -----------------------------------------------------------------
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
    # -----------------------------------------------------------------

    
    # -----------------------------------------------------------------
    # Copy file/folder to explicit destination path
    # -----------------------------------------------------------------
    bkpfolder = ''
      set -l src (string replace -r '/+$' "" -- "$argv[1]")
      set -l dest (string replace -r '/+$' "" -- "$argv[2]")
  
      if test -z "$src"; or test -z "$dest"; or not test -e "$src"
        echo "Usage: bkpfolder <path/to/file/or/folder> <destination/path>"
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
    # -----------------------------------------------------------------
  

    # -----------------------------------------------------------------
    # ---- archive_clean_folder -> Clean and archive folder ---- #
    # Downloads all iCloud files, removes common junk files,
    # creates and verifies a zip, then deletes the source folder
    #
    # Usage:
    # archive_clean_folder <source> <destination> [required_suffix]
    #
    # Example:
    # archive_clean_folder ./Gruvbox ~/.config/theme-archives "-theme"
    # -----------------------------------------------------------------
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

      find "$staged_folder" -depth \( \
        -name ".git" -o \
        -name ".github" -o \
        -name ".gitignore" -o \
        -name ".gitattributes" -o \
        -name ".gitmodules" \
      \) -exec rm -rf -- {} +

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
    # -----------------------------------------------------------------
  };
}
