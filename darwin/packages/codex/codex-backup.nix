# darwin/packages/codex/codex-backup.nix

# ================================================================================================
# This script creates a backup of the Codex configuration directory in the user's iCloud Drive.
# It is intended to be run automatically by a launchd user agent, but can also be run manually.
# The backup is skipped if the source directory does not exist, if another backup is already running, if the previous backup was less than eight hours ago, or if no changes have been made since the previous backup.
# The backup is created as a compressed tar archive with macOS metadata preserved.
# The script also logs its output and errors to files in the user's Library/Logs directory.
# The script is written in a way that it can be used as a Nix package, so that it can be easily installed and managed by the Nix package manager.
# The script uses standard Unix utilities such as find, tar, and date, and is compatible with macOS.
# The script is written in a way that it can be used as a Nix package, so that it can be easily installed and managed by the Nix package manager.
# ================================================================================================

{ pkgs, ... }:

let
  # Run the shell script
  codexBackup = pkgs.writeShellScriptBin "codex-backup" ''
    set -euo pipefail
    # Set the default mode to manual, which allows the script to be run without any arguments. The --scheduled argument is used when the script is run by launchd.
    mode="manual"

    # Parse the command line arguments. The script accepts only one optional argument: --scheduled. If any other argument is provided, the script prints a usage message and exits with an error code.
    case "''${1:-}" in
      "")
        ;;
      --scheduled)
        mode="scheduled"
        ;;
      *)
        printf 'Usage: codex-backup [--scheduled]\n' >&2
        exit 2
        ;;
    esac

    # Source and destination directories
    source_parent="/Users/ven/.config"
    source_name="codex"
    source_dir="$source_parent/$source_name"

    external_backup_root="/Volumes/SystemBackup"
    backup_dir="$external_backup_root/data-backups/container-backups/codex"
    local_staging_dir="/Users/ven/Downloads/backup-staging/codex"
    marker_file="$backup_dir/.last-backup"
    lock_dir="/private/tmp/com.ven.codex-backup.lock"
    global_lock_dir="/private/tmp/com.ven.backup-archive.lock"
    cpu_limit_percent=35

    temp_archive=""
    local_archive=""
    run_marker=""
    global_lock_acquired=0

    # Cleanup function to remove temp files and directories
    cleanup() {

      # Remove the temporary archive only if it still exists. It may have been renamed to the final archive if the backup completed successfully.
      if [ -n "$temp_archive" ]; then
        ${pkgs.coreutils}/bin/rm -f "$temp_archive"
      fi

      # Remove the run marker only if it still exists. It may have been renamed to the marker file if the backup completed successfully.
      if [ -n "$run_marker" ]; then
        ${pkgs.coreutils}/bin/rm -f "$run_marker"
      fi

      # Remove only the exact per-backup and global lock directories.
      ${pkgs.coreutils}/bin/rm -f -- "$lock_dir/pid" 2>/dev/null || true
      ${pkgs.coreutils}/bin/rmdir -- "$lock_dir" 2>/dev/null || true
      if [ "$global_lock_acquired" -eq 1 ]; then
        ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
      fi
    }

    # Check if the source directory exists. If it does not exist, print an error message and exit with an error code.
    if [ ! -d "$source_dir" ]; then
      printf 'Codex backup failed: source directory does not exist: %s\n' \
        "$source_dir" >&2
      exit 1
    fi

    if [ ! -d "$external_backup_root" ]; then
      printf 'Codex backup failed: external backup volume is not available: %s\n' \
        "$external_backup_root" >&2
      exit 1
    fi

    if ! /sbin/mount | ${pkgs.gnugrep}/bin/grep -F \
        " on $external_backup_root (" >/dev/null; then
      printf 'Codex backup failed: external backup volume is not mounted: %s\n' \
        "$external_backup_root" >&2
      exit 1
    fi

    # Create only the configured directory on the mounted external backup volume.
    ${pkgs.coreutils}/bin/mkdir -p "$backup_dir"

    ${pkgs.coreutils}/bin/mkdir -p "$local_staging_dir"

    if [ ! -d "$local_staging_dir" ]; then
      printf 'Codex backup failed: local staging directory does not exist: %s\n' \
        "$local_staging_dir" >&2
      exit 1
    fi

    # Prevent two backups from running simultaneously.
    if ! ${pkgs.coreutils}/bin/mkdir "$lock_dir" 2>/dev/null; then
      old_pid=""

      # Read the PID of the previous backup from the lock directory. If the PID file does not exist or cannot be read, old_pid will be empty.
      if [ -r "$lock_dir/pid" ]; then
        IFS= read -r old_pid < "$lock_dir/pid" || true
      fi

      # Check if the previous backup is still running by sending a signal 0 to the PID. If the process exists, kill -0 will return success, and we will skip the backup. If the process does not exist, kill -0 will return an error, and we will remove the lock directory and create a new one.
      if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        printf 'Codex backup skipped: another backup is already running.\n'
        exit 0
      fi

      # Remove a lock left behind by a crash or forced shutdown.
      ${pkgs.coreutils}/bin/rm -f -- "$lock_dir/pid"
      ${pkgs.coreutils}/bin/rmdir -- "$lock_dir" || {
        printf 'Codex backup failed: refusing to replace lock: %s\n' \
          "$lock_dir" >&2
        exit 1
      }
      ${pkgs.coreutils}/bin/mkdir "$lock_dir"
    fi

    # Write the PID of the current backup to the lock directory. This allows future backups to check if a backup is already running.
    printf '%s\n' "$$" > "$lock_dir/pid"

    trap cleanup EXIT INT TERM

    # Automatic launchd runs only create a backup when at least eight hours
    # have passed since the previous successful backup.
    #
    # Manual runs through `codex-backup` bypass this time restriction.
    if [ "$mode" = "scheduled" ] && [ -e "$marker_file" ]; then
      current_time="$(
        ${pkgs.coreutils}/bin/date '+%s'
      )"

      # Get the modification time of the marker file, which indicates when the last successful backup was completed. The stat command is used to retrieve the modification time in seconds since the epoch.
      previous_backup_time="$(
        /usr/bin/stat -f '%m' "$marker_file"
      )"

      # Calculate the elapsed time in seconds since the last successful backup. This is done by subtracting the previous backup time from the current time.
      elapsed_seconds="$((current_time - previous_backup_time))"

      # If the elapsed time since the last successful backup is less than 8 hours (28800 seconds), skip creating a new backup and print a message indicating how many seconds remain until the next scheduled backup.
      if [ "$elapsed_seconds" -lt 28800 ]; then
        remaining_seconds="$((28800 - elapsed_seconds))"

        # Print a message indicating that the backup is being skipped and how many seconds remain until the next scheduled backup. The printf command is used to format the message with the remaining seconds.
        printf \
          'Codex backup skipped: the next scheduled backup is due in %s seconds.\n' \
          "$remaining_seconds"

        exit 0
      fi
    fi

    # Do not create another archive when nothing has changed.
    if [ -e "$marker_file" ]; then
      # Check if any files in the source directory have been modified since the last successful backup. The find command is used to search for files that are newer than the marker file, which indicates the last successful backup. If no such files are found, the backup is skipped.
      # Search for files in the source directory and its subdirectories.
      # Timestamp of the last successful backup
      # ** If any file is newer than this timestamp, it means that changes have been made since the last backup.
      # Print the path of the file found that is newer than the marker file set. The print action is used to output the path of the file to the standard output. If no files are found, the output will be empty, and the backup will be skipped.
      # Exit after the first match newer than the marker is found
      changed_path="$(
        ${pkgs.findutils}/bin/find "$source_dir" \
          -newer "$marker_file" \
          -print \
          -quit
      )"

      # If no files have changed since the last successful backup, skip creating a new backup and print a message indicating that the backup is being skipped.
      if [ -z "$changed_path" ]; then
        printf \
          'Codex backup skipped: no changes since the previous successful backup.\n'
        exit 0
      fi
    fi

    # Only one backup may compress, verify, or hand off to external storage at once.
    if ! ${pkgs.coreutils}/bin/mkdir "$global_lock_dir" 2>/dev/null; then
      global_old_pid=""

      if [ -r "$global_lock_dir/pid" ]; then
        IFS= read -r global_old_pid < "$global_lock_dir/pid" || true
      fi

      if [ -n "$global_old_pid" ] && kill -0 "$global_old_pid" 2>/dev/null; then
        printf 'Codex backup skipped: another backup is archiving or uploading.\n'
        exit 0
      fi

      ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid"
      ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" || {
        printf 'Codex backup failed: refusing to replace global lock: %s\n' \
          "$global_lock_dir" >&2
        exit 1
      }
      ${pkgs.coreutils}/bin/mkdir "$global_lock_dir"
    fi

    printf '%s\n' "$$" > "$global_lock_dir/pid"
    global_lock_acquired=1

    # Create a timestamp for the backup archive name
    # ** Date format: YYYY-MM-DD_HH-MM-SS
    timestamp="$(
      ${pkgs.coreutils}/bin/date '+%Y-%m-%d_%H-%M-%S'
    )"

    # File template for the backup archive name with timestamp included
    archive="$backup_dir/codex-$timestamp.tar.gz"
    local_archive="$local_staging_dir/codex-$timestamp.tar.gz"

    # Never overwrite an existing local or iCloud backup.
    if [ -e "$archive" ] || [ -e "$local_archive" ]; then
      archive="$backup_dir/codex-$timestamp-$$.tar.gz"
      local_archive="$local_staging_dir/codex-$timestamp-$$.tar.gz"
    fi

    # Create a temporary archive name to avoid leaving a partially created archive in the destination directory
    temp_archive="$local_staging_dir/.codex-$timestamp-$$.tar.gz.incomplete"
    run_marker="$local_staging_dir/.codex-backup-start-$$"

    # Preserve the time at which this backup started. Changes made while the
    # archive is being created will therefore be detected by the next run.
    ${pkgs.coreutils}/bin/touch "$run_marker"

    printf 'Creating local Codex backup: %s\n' "$local_archive"

    # The macOS bsdtar implementation preserves symlinks without following
    # them. The explicit metadata options also preserve macOS ACLs, extended
    # attributes, resource forks, file flags, permissions and timestamps.
    (
      cd "$source_parent"

      # Exclude macOS junk files and directories
      # Exclude Unix domain sockets because bsdtar cannot archive them.
      ${pkgs.findutils}/bin/find "$source_name" \
        \( \
          -type s \
        \) \
        -prune \
        -o \
        \( \
          -type d \
          \( \
            -name "__MACOSX" -o \
            -name ".AppleDouble" -o \
            -name ".Spotlight-V100" -o \
            -name ".Trashes" -o \
            -name ".fseventsd" -o \
            -name ".TemporaryItems" -o \
            -name ".DocumentRevisions-V100" \
          \) \
          -prune \
        \) -o \
        \( \
          -name ".DS_Store" -o \
          -name ".LSOverride" -o \
          -name "._*" -o \
          -name $'Icon\r' \
        \) \
        -prune -o \
        -print0 |
        ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
          /usr/bin/tar \
          --format pax \
          --mac-metadata \
          --acls \
          --xattrs \
          --fflags \
          --null \
          --no-recursion \
          -czf "$temp_archive" \
          -T -
    )

    # Verify that the completed archive can be read before accepting it.
    ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
      /usr/bin/tar -tzf "$temp_archive" > /dev/null

    # Complete and verify locally before handing the archive to iCloud.
    ${pkgs.coreutils}/bin/mv "$temp_archive" "$local_archive"
    temp_archive=""

    printf 'Moving verified Codex backup to external storage: %s\n' "$archive"
    if ! ${pkgs.coreutils}/bin/mv "$local_archive" "$archive"; then
      printf 'Codex backup failed: verified local archive remains at: %s\n' \
        "$local_archive" >&2
      exit 1
    fi

    local_archive=""

    # Only update the marker after creation and verification succeeded.
    ${pkgs.coreutils}/bin/mv -f "$run_marker" "$marker_file"
    run_marker=""

    printf 'Codex backup completed successfully: %s\n' "$archive"
  '';
in
{
  environment.systemPackages = [
    codexBackup
  ];


  launchd.user.agents.codex-backup = {
    serviceConfig = {
      ProgramArguments = [
        "${codexBackup}/bin/codex-backup"
        "--scheduled"
      ];

      # Do not begin a large backup while the user is logging in or switching generations.
      RunAtLoad = false;

      # Check every eight hours. The runner creates an archive only when
      # the Codex directory changed since the previous successful backup.
      StartInterval = 28800;

      # Run the backup with low priority to avoid interfering with other tasks.
      ProcessType = "Background";
      Nice = 20;
      LowPriorityIO = true;
      LowPriorityBackgroundIO = true;

      # Log output and errors to files in the user's Library/Logs directory.
      StandardOutPath =
        "/Users/ven/Library/Logs/codex-backup.log";

      StandardErrorPath =
        "/Users/ven/Library/Logs/codex-backup-error.log";
    };
  };
}
