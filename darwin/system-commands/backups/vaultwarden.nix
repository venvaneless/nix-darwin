# darwin/system-commands/backups/vaultwarden.nix
#
# Backs up Vaultwarden container data to SystemBackup. The SQLite database
# is copied with SQLite's online backup API before the ZIP is created.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Vaultwarden";
  appSlug = "vaultwarden";
  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;
  sourceDir = "/Users/ven/.config/containers/vaultwarden";
  scheduledHour = 4;
  scheduledMinute = 0;

  prepareArchive = ''
    staging_dir="$(
      ${pkgs.coreutils}/bin/mktemp -d "/private/tmp/vaultwarden-backup.XXXXXX"
    )"
    archive_source_parent="$staging_dir"
    archive_source_name="$source_name"
    staged_source="$staging_dir/$source_name"

    ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"
    ${pkgs.rsync}/bin/rsync -a \
      --exclude='.DS_Store' \
      --exclude='._*' \
      --exclude='.AppleDouble' \
      --exclude='.DocumentRevisions-V100' \
      --exclude='.fseventsd' \
      --exclude='.LSOverride' \
      --exclude='.Spotlight-V100' \
      --exclude='.TemporaryItems' \
      --exclude='.Trashes' \
      --exclude='.Trash' \
      --exclude='.Trash-*' \
      --exclude='__MACOSX' \
      --exclude='db.sqlite3' \
      --exclude='db.sqlite3-shm' \
      --exclude='db.sqlite3-wal' \
      -- "$source_dir/" "$staged_source/"

    if [ ! -f "$source_dir/db.sqlite3" ]; then
      fail "Vaultwarden SQLite database does not exist: $source_dir/db.sqlite3"
    fi

    ${pkgs.coreutils}/bin/timeout 300 \
      ${pkgs.sqlite}/bin/sqlite3 \
      "$source_dir/db.sqlite3" \
      ".backup '$staged_source/db.sqlite3'"
  '';
}
