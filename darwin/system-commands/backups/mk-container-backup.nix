# darwin/system-commands/backups/mk-container-backup.nix
#
# =====================================================================
# CONTAINER BACKUP HELPER
#
# Creates a manual command, optional LaunchAgent, and optional rebuild
# hook for one container directory. Each backup is a verified ZIP in
# iCloud Drive and uses .last-backup to gate scheduled runs.
# =====================================================================

{
  config,
  lib,
  pkgs,
  appName,
  appSlug,
  sourceDir,
  prepareArchive ? "",
}:

let
  cfg = config.services.containerBackups.${appSlug};
  backupCfg = config.services.containerBackups;

  commandName = "${appSlug}-backup";
  launchdLabel = "com.ven.backup.${appSlug}";

  backupRunner = pkgs.writeShellApplication {
    name = commandName;

    runtimeInputs = with pkgs; [
      coreutils
      findutils
      rsync
      sqlite
      unzip
      zip
    ];

    text = ''
      set -euo pipefail

      # -----------------------------------------------------------------
      # BACKUP PATHS
      # -----------------------------------------------------------------
      app_name=${lib.escapeShellArg appName}
      app_slug=${lib.escapeShellArg appSlug}
      source_dir=${lib.escapeShellArg sourceDir}
      iCloud_root="/Users/ven/iCloudDocs"
      backup_root="$iCloud_root/Documents/data-backups/container-backups"
      destination_dir="$backup_root/$app_slug"

      marker_file="$destination_dir/.last-backup"
      lock_dir="$destination_dir/.$app_slug-backup.lock"
      backup_interval_seconds=28800

      mode="manual"
      temporary_archive=""
      temporary_marker=""
      staging_dir=""

      usage() {
        printf 'Usage: %s [--scheduled|--rebuild]\n' "$0" >&2
      }

      fail() {
        printf '%s backup failed: %s\n' "$app_name" "$*" >&2
        exit 1
      }

      log() {
        printf '[%s backup] %s\n' "$app_slug" "$*"
      }

      release_lock() {
        ${pkgs.coreutils}/bin/rm -f -- "$lock_dir/pid" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rmdir -- "$lock_dir" 2>/dev/null || true
      }

      cleanup() {
        if [ -n "$temporary_archive" ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$temporary_archive" 2>/dev/null || true
        fi

        if [ -n "$temporary_marker" ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$temporary_marker" 2>/dev/null || true
        fi

        if [ -n "$staging_dir" ] && [ -d "$staging_dir" ]; then
          ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir" 2>/dev/null || true
        fi

        release_lock
      }

      case "''${1:-}" in
        "")
          ;;
        --scheduled)
          mode="scheduled"
          ;;
        --rebuild)
          mode="rebuild"
          ;;
        *)
          usage
          exit 2
          ;;
      esac

      if [ ! -d "$source_dir" ]; then
        fail "source directory does not exist: $source_dir"
      fi

      if [ ! -d "$iCloud_root" ]; then
        fail "iCloud Drive is not available at: $iCloud_root"
      fi

      # Create only this explicitly configured iCloud backup directory.
      ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"

      if [ ! -d "$destination_dir" ]; then
        fail "could not create backup directory: $destination_dir"
      fi

      if ! ${pkgs.coreutils}/bin/mkdir -- "$lock_dir" 2>/dev/null; then
        previous_pid=""

        if [ -r "$lock_dir/pid" ]; then
          IFS= read -r previous_pid < "$lock_dir/pid" || true
        fi

        if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
          log "skipped: another backup is already running"
          exit 0
        fi

        ${pkgs.coreutils}/bin/rm -f -- "$lock_dir/pid"
        ${pkgs.coreutils}/bin/rmdir -- "$lock_dir" || \
          fail "refusing to replace an unexpected lock directory: $lock_dir"
        ${pkgs.coreutils}/bin/mkdir -- "$lock_dir"
      fi

      printf '%s\n' "$$" > "$lock_dir/pid"
      trap cleanup EXIT INT TERM

      if [ -e "$marker_file" ]; then
        previous_backup_epoch="$(
          ${pkgs.coreutils}/bin/stat -c '%Y' "$marker_file"
        )"
        previous_backup_time="$(
          ${pkgs.coreutils}/bin/date -d "@$previous_backup_epoch" '+%Y-%m-%d %H:%M:%S %Z'
        )"
        log "last successful backup: $previous_backup_time"

        if [ "$mode" = "scheduled" ]; then
          current_epoch="$(
            ${pkgs.coreutils}/bin/date '+%s'
          )"
          elapsed_seconds="$((current_epoch - previous_backup_epoch))"

          if [ "$elapsed_seconds" -lt "$backup_interval_seconds" ]; then
            remaining_seconds="$((backup_interval_seconds - elapsed_seconds))"
            log "skipped: next scheduled backup is due in $remaining_seconds seconds"
            exit 0
          fi
        fi
      else
        log "no successful backup marker exists yet"
      fi

      if [ -e "$marker_file" ]; then
        changed_path="$(
          ${pkgs.findutils}/bin/find "$source_dir" \
            \( \
              -name '.DS_Store' -o \
              -name '._*' -o \
              -name '.AppleDouble' -o \
              -name '.DocumentRevisions-V100' -o \
              -name '.fseventsd' -o \
              -name '.LSOverride' -o \
              -name '.Spotlight-V100' -o \
              -name '.TemporaryItems' -o \
              -name '.Trashes' -o \
              -name '.Trash' -o \
              -name '.Trash-*' -o \
              -name '__MACOSX' -o \
              -name 'Icon'$'\r' -o \
              -name 'Thumbs.db' -o \
              -name 'desktop.ini' \
            \) -prune -o \
            -newer "$marker_file" -print -quit
        )"

        if [ -z "$changed_path" ]; then
          log "skipped: no source changes since the previous successful backup"
          exit 0
        fi

        log "detected source change: $changed_path"
      fi

      source_parent="$(
        ${pkgs.coreutils}/bin/dirname -- "$source_dir"
      )"
      source_name="$(
        ${pkgs.coreutils}/bin/basename -- "$source_dir"
      )"
      archive_source_parent="$source_parent"
      archive_source_name="$source_name"

      ${prepareArchive}

      timestamp="$(
        ${pkgs.coreutils}/bin/date '+%Y-%m-%d-%H%M'
      )"
      archive="$destination_dir/$timestamp-$app_slug.zip"
      temporary_archive="$destination_dir/.$timestamp-$app_slug-$$.zip.incomplete"
      temporary_marker="$destination_dir/.last-backup-$$.incomplete"

      if [ -e "$archive" ]; then
        fail "refusing to overwrite an existing archive: $archive"
      fi

      log "creating archive: $archive"

      (
        cd -- "$archive_source_parent"

        ${pkgs.zip}/bin/zip -q -r -y "$temporary_archive" "$archive_source_name" \
          -x '*/.DS_Store' \
          -x '*/._*' \
          -x '*/.AppleDouble' \
          -x '*/.AppleDouble/*' \
          -x '*/.DocumentRevisions-V100' \
          -x '*/.DocumentRevisions-V100/*' \
          -x '*/.fseventsd' \
          -x '*/.fseventsd/*' \
          -x '*/.LSOverride' \
          -x '*/.Spotlight-V100' \
          -x '*/.Spotlight-V100/*' \
          -x '*/.TemporaryItems' \
          -x '*/.TemporaryItems/*' \
          -x '*/.Trashes' \
          -x '*/.Trashes/*' \
          -x '*/.Trash' \
          -x '*/.Trash/*' \
          -x '*/.Trash-*' \
          -x '*/.Trash-*/*' \
          -x '*/__MACOSX' \
          -x '*/__MACOSX/*' \
          -x '*/Icon?' \
          -x '*/Thumbs.db' \
          -x '*/desktop.ini'
      )

      ${pkgs.unzip}/bin/unzip -t "$temporary_archive" >/dev/null
      ${pkgs.coreutils}/bin/mv -- "$temporary_archive" "$archive"
      temporary_archive=""

      successful_backup_time="$(
        ${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S %Z'
      )"
      successful_backup_epoch="$(
        ${pkgs.coreutils}/bin/date '+%s'
      )"

      {
        printf 'last_successful_backup=%s\n' "$successful_backup_time"
        printf 'last_successful_backup_epoch=%s\n' "$successful_backup_epoch"
        printf 'archive=%s\n' "$archive"
        printf 'source=%s\n' "$source_dir"
      } > "$temporary_marker"

      if ! ${pkgs.coreutils}/bin/mv -f -- "$temporary_marker" "$marker_file"; then
        ${pkgs.coreutils}/bin/rm -f -- "$archive"
        fail "could not update backup marker: $marker_file"
      fi

      temporary_marker=""
      log "completed successfully: $archive"
    '';
  };
in
{
  options.services.containerBackups.${appSlug} = {
    enable = lib.mkEnableOption "${appName} container backup";

    automatic = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the ${appName} backup automatically through LaunchAgent checks.";
    };

    runOnRebuild = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include the ${appName} backup when services.containerBackups.runOnRebuild is enabled.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [ backupRunner ];
    }

    (lib.mkIf cfg.automatic {
      launchd.agents."backup-${appSlug}" = {
        serviceConfig = {
          Label = launchdLabel;
          ProgramArguments = [
            "${backupRunner}/bin/${commandName}"
            "--scheduled"
          ];
          RunAtLoad = true;
          KeepAlive = false;
          StartInterval = 900;
          LowPriorityIO = true;
          LowPriorityBackgroundIO = true;
          StandardOutPath = "/Users/ven/Library/Logs/${commandName}.log";
          StandardErrorPath = "/Users/ven/Library/Logs/${commandName}-error.log";
        };
      };
    })

    (lib.mkIf (backupCfg.runOnRebuild && cfg.runOnRebuild) {
      system.activationScripts."run-${appSlug}-backup".text = lib.mkAfter ''
        echo ">>> [${appSlug} backup] Running requested rebuild backup"
        /usr/bin/sudo -H -u ven "${backupRunner}/bin/${commandName}" --rebuild \
          || echo ">>> [${appSlug} backup] Rebuild backup failed (continued)"
      '';
    })
  ]);
}
