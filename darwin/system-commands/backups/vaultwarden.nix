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
  # ---- SHARED PATHS ---- #
  # The lock directory root comes from the centralized path definitions;
  # the source and destination roots stay on the container backup options
  # so a host can still override them.
  paths = import ../../../options/paths.nix { };

  appSlug = "vaultwarden";

  # ---- BACKUP PATHS
  # ** The source is the directory the Vaultwarden service itself
  # ** declares, so the backup follows the service if that data
  # ** directory moves.
  #
  # ** Destination and staging directories are registered under
  # ** darwin.backups.perContainer in options/paths.nix and resolved by
  # ** the helper from appSlug. Change them there, not here.
  vaultwardenSourceDir = config.ven.vaultwarden.dataDir;

  # Additional paths are added only to the staged archive, never live data.
  additionalSources = [ ];

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  showProgress = true;
  runOnRebuild = false;
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "vaultwarden";
  preserveSymlinks = true;
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Vaultwarden";
  appSlug = "vaultwarden";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress runOnRebuild additionalSources extraExcludePatterns;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  sourceDir = vaultwardenSourceDir;
  scheduledHour = 4;
  scheduledMinute = 0;

  prepareArchive = ''
    staging_dir="$(
      ${pkgs.coreutils}/bin/mktemp -d "${paths.darwin.backups.lockRoot}/${appSlug}-backup.XXXXXX"
    )"
    archive_source_parent="$staging_dir"
    archive_source_name="$source_name"
    staged_source="$staging_dir/$source_name"

    ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"
    backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" \
      --exclude='db.sqlite3' \
      --exclude='db.sqlite3-shm' \
      --exclude='db.sqlite3-wal' \
      -- "$source_dir/" "$staged_source/"

    if [ ! -f "$source_dir/db.sqlite3" ]; then
      fail "Vaultwarden SQLite database does not exist: $source_dir/db.sqlite3"
    fi

    ${pkgs.coreutils}/bin/timeout 300 \
      ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
      ${pkgs.sqlite}/bin/sqlite3 \
      "$source_dir/db.sqlite3" \
      ".backup '$staged_source/db.sqlite3'"
  '';
}
