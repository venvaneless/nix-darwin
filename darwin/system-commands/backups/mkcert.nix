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

{ lib, pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # The CA root, the backup volume layout, and the mount check come from
  # the centralized path definitions.
  paths = import ../../../options/paths.nix { };
  backupPaths = paths.darwin.backups;

  # ---- BACKUP PATHS
  # ** Certificates live beside the other data backups rather than under
  # ** app-backups, because this is a mirror and not an application
  # ** archive. Change the location in options/paths.nix.
  sourceDir = paths.darwin.home.mkcert;
  destinationDir = backupPaths.certificates;

  mkcertBackup = pkgs.writeShellApplication {
    name = "mkcert-backup";
    runtimeInputs = with pkgs; [ coreutils gnugrep rsync ];
    text = ''
      set -euo pipefail

      source_dir="${sourceDir}"
      destination_dir="${destinationDir}"
      external_backup_volume="${backupPaths.volume}"

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
        ${pkgs.rsync}/bin/rsync -a --itemize-changes --dry-run \
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

      ${pkgs.rsync}/bin/rsync -a -- "$source_dir/" "$destination_dir/"
      echo "[mkcert backup] DONE $destination_dir"
    '';
  };
in
{
  environment.systemPackages = [ mkcertBackup ];
}
