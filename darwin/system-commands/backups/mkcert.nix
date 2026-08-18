# darwin/system-commands/backups/mkcert.nix
#
# =====================================================================
# MKCERT BACKUP
#
# Mirrors the mkcert CA directory to the external backup volume as
# `mkcert-backup`.
#
# - No archive and no timestamped copies: the destination is a plain
#   mirror, so restoring is a straight copy back.
# - Nothing is written when the certificates have not changed, whether
#   the command runs manually or from a schedule.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # The CA root, the backup volume layout, and the mount check come from
  # the centralized path definitions.
  paths = import ../../../options/paths.nix { };
  backupPaths = paths.darwin.backups;
  excludeHelper = import ./backup-exclude-helper.nix { inherit lib; };

  # ---- BACKUP PATHS
  # ** Certificates live beside the other data backups rather than under
  # ** app-backups, because this is a mirror and not an application
  # ** archive. Change the location in options/paths.nix.
  sourceDir = paths.darwin.home.mkcert;
  destinationDir = backupPaths.certificates;
  showProgress = true;
  progressEnabled = config.services.appBackups.mkcert.showProgress;
  defaultMetadataExcludes = excludeHelper.mkRsyncExcludeArguments excludeHelper.defaultMetadataExcludePatterns;

  mkcertBackup = pkgs.writeShellApplication {
    name = "mkcert-backup";
    runtimeInputs = with pkgs; [ cpulimit coreutils gnugrep rsync ];
    text = ''
      set -euo pipefail

      source_dir="${sourceDir}"
      destination_dir="${destinationDir}"
      external_backup_volume="${backupPaths.volume}"
      cpu_limit_percent=10
      transfer_limit_kibps=4096
      show_progress=${if progressEnabled then "1" else "0"}
      rsync_progress_args=()
      if [ "$show_progress" -eq 1 ]; then
        rsync_progress_args+=(--info=progress2)
      fi
      exclude_args=(
${defaultMetadataExcludes}
      )
      global_lock_dir="${backupPaths.archiveLock}"
      global_lock_acquired=0

      backup_process() {
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- "$@"
      }

      fail() {
        echo "[mkcert backup] ERROR $*" >&2
        exit 1
      }

      release_backup_lock() {
        if [ "$global_lock_acquired" -eq 1 ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
        fi
      }

      acquire_backup_lock() {
        if ! ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir" 2>/dev/null; then
          previous_pid=""
          if [ -r "$global_lock_dir/pid" ]; then
            IFS= read -r previous_pid < "$global_lock_dir/pid" || true
          fi
          if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
            fail "another backup is already running"
          fi
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid"
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" || fail "refusing to replace an unexpected backup lock"
          ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir"
        fi

        printf '%s\n' "$$" > "$global_lock_dir/pid"
        global_lock_acquired=1
      }

      trap release_backup_lock EXIT
      trap 'exit 130' INT TERM

      # ---- PREREQUISITES ---- #

      if [ ! -d "$source_dir" ]; then
        echo "[mkcert backup] ERROR missing source: $source_dir" >&2
        exit 1
      fi

      # ** An unmounted volume leaves a writable empty directory at the
      # ** same path, so the mount itself has to be verified.
      if [ ! -d "$external_backup_volume" ] || ! ${paths.darwin.system.bin.mount} | ${pkgs.gnugrep}/bin/grep -Fq " on $external_backup_volume "; then
        echo "[mkcert backup] ERROR external backup volume is not mounted" >&2
        exit 1
      fi

      acquire_backup_lock
      ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"

      # ---- CHANGE DETECTION ---- #
      # A dry run lists one line per item rsync would transfer. Lines
      # beginning with a dot are items rsync is leaving alone, so they
      # are dropped and only real content changes remain.
      #
      # ** This keeps a manual run free of side effects when nothing has
      # ** changed: the mirror is not touched and its timestamps stay as
      # ** they were at the last real backup.
      pending="$(
        ${pkgs.rsync}/bin/rsync -a --itemize-changes --dry-run "''${exclude_args[@]}" \
          -- "$source_dir/" "$destination_dir/" \
          | ${pkgs.gnugrep}/bin/grep -v '^\.' || true
      )"

      if [ -z "$pending" ]; then
        echo "[mkcert backup] SKIP no certificate changes since the last backup"
        exit 0
      fi

      # ---- SYNC ---- #

      echo "[mkcert backup] CHANGED:"
      printf '%s\n' "$pending" | while IFS= read -r change; do
        echo "[mkcert backup]   $change"
      done

      backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- "$source_dir/" "$destination_dir/"
      echo "[mkcert backup] DONE $destination_dir"
    '';
  };
in
{
  options.services.appBackups.mkcert = {
    showProgress = lib.mkOption {
      type = lib.types.bool;
      default = showProgress;
      description = "Show rsync transfer progress for the mkcert backup.";
    };
  };

  config.environment.systemPackages = [ mkcertBackup ];
}
