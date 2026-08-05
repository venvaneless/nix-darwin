# darwin/system-commands/backups/mkcert.nix
# mkcert backup command: `mkcert-backup`.

{ lib, pkgs, ... }:

let
  mkcertBackup = pkgs.writeShellApplication {
    name = "mkcert-backup";
    runtimeInputs = with pkgs; [ coreutils rsync ];
    text = ''
      set -euo pipefail

      external_backup_volume="/Volumes/SystemBackup"
      data_backups_root="$external_backup_volume/data-backups"
      app_backups_root="$data_backups_root/app-backups"
      source_dir="/Users/ven/.config/mkcert"
      destination_dir="$app_backups_root/mkcert"

      if [ ! -d "$source_dir" ]; then
        echo "[mkcert backup] ERROR missing source: $source_dir" >&2
        exit 1
      fi

      if [ ! -d "$external_backup_volume" ] || ! /sbin/mount | ${pkgs.gnugrep}/bin/grep -Fq " on $external_backup_volume "; then
        echo "[mkcert backup] ERROR external backup volume is not mounted" >&2
        exit 1
      fi

      ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"
      ${pkgs.rsync}/bin/rsync -a -- "$source_dir/" "$destination_dir/"
      echo "[mkcert backup] DONE $destination_dir"
    '';
  };
in
{
  environment.systemPackages = [ mkcertBackup ];
}
