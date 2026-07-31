# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/codex/codex-backup.nix

{ pkgs, ... }:

let
  codexBackup = pkgs.writeShellScript "codex-backup" ''
    set -euo pipefail

    source_parent="/Users/ven/.config"
    source_name="codex"
    source_dir="$source_parent/$source_name"

    backup_dir="/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/data-backups/codex"
    marker_file="$backup_dir/.last-backup"
    lock_dir="$backup_dir/.codex-backup.lock"

    temp_archive=""
    run_marker=""

    cleanup() {
      if [ -n "$temp_archive" ]; then
        ${pkgs.coreutils}/bin/rm -f "$temp_archive"
      fi

      if [ -n "$run_marker" ]; then
        ${pkgs.coreutils}/bin/rm -f "$run_marker"
      fi

      ${pkgs.coreutils}/bin/rm -rf "$lock_dir"
    }

    if [ ! -d "$source_dir" ]; then
      printf 'Codex backup failed: source directory does not exist: %s\n' \
        "$source_dir" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$backup_dir"

    # Prevent two backups from running simultaneously.
    if ! ${pkgs.coreutils}/bin/mkdir "$lock_dir" 2>/dev/null; then
      old_pid=""

      if [ -r "$lock_dir/pid" ]; then
        IFS= read -r old_pid < "$lock_dir/pid" || true
      fi

      if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        printf 'Codex backup skipped: another backup is already running.\n'
        exit 0
      fi

      # Remove a lock left behind by a crash or forced shutdown.
      ${pkgs.coreutils}/bin/rm -rf "$lock_dir"
      ${pkgs.coreutils}/bin/mkdir "$lock_dir"
    fi

    printf '%s\n' "$$" > "$lock_dir/pid"

    trap cleanup EXIT INT TERM

    # Do not create another archive when nothing has changed.
    if [ -e "$marker_file" ]; then
      changed_path="$(
        ${pkgs.findutils}/bin/find \
          "$source_dir" \
          -newer "$marker_file" \
          -print \
          -quit
      )"

      if [ -z "$changed_path" ]; then
        printf \
          'Codex backup skipped: no changes since the previous successful backup.\n'
        exit 0
      fi
    fi

    timestamp="$(
      ${pkgs.coreutils}/bin/date '+%Y-%m-%d_%H-%M-%S'
    )"

    archive="$backup_dir/codex-$timestamp.tar.gz"

    if [ -e "$archive" ]; then
      archive="$backup_dir/codex-$timestamp-$$.tar.gz"
    fi

    temp_archive="$backup_dir/.codex-$timestamp-$$.tar.gz.incomplete"
    run_marker="$backup_dir/.codex-backup-start-$$"

    # Preserve the time at which this backup started. Changes made while the
    # archive is being created will therefore be detected by the next run.
    ${pkgs.coreutils}/bin/touch "$run_marker"

    printf 'Creating Codex backup: %s\n' "$archive"

    # The macOS bsdtar implementation preserves symlinks without following
    # them. The explicit metadata options also preserve macOS ACLs, extended
    # attributes, resource forks, file flags, permissions and timestamps.
    (
      cd "$source_parent"

      ${pkgs.findutils}/bin/find "$source_name" \
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
          -type s -o \
          -name ".DS_Store" -o \
          -name ".LSOverride" -o \
          -name "._*" -o \
          -name $'Icon\r' \
        \) \
        -prune -o \
        -print0 |
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
    /usr/bin/tar -tzf "$temp_archive" > /dev/null

    # The temporary archive is in the destination directory, so this rename
    # completes the backup atomically.
    ${pkgs.coreutils}/bin/mv "$temp_archive" "$archive"
    temp_archive=""

    # Only update the marker after creation and verification succeeded.
    ${pkgs.coreutils}/bin/mv -f "$run_marker" "$marker_file"
    run_marker=""

    printf 'Codex backup completed successfully: %s\n' "$archive"
  '';
in
{
  launchd.user.agents.codex-backup = {
    serviceConfig = {
      ProgramArguments = [
        "${codexBackup}"
      ];

      # Run whenever the user agent is loaded after login.
      RunAtLoad = true;

      # Run every eight hours. Missed runs during sleep are coalesced into
      # one run after the Mac wakes.
      StartInterval = 28800;

      LowPriorityIO = true;
      LowPriorityBackgroundIO = true;

      StandardOutPath =
        "/Users/ven/Library/Logs/codex-backup.log";

      StandardErrorPath =
        "/Users/ven/Library/Logs/codex-backup-error.log";
    };
  };
}