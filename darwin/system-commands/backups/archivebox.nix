# darwin/system-commands/backups/archivebox.nix
#
# Backs up ArchiveBox container data to SystemBackup. The SQLite database
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

  appSlug = "archivebox";

  # ---- BACKUP PATHS
  # ** The source is the directory the ArchiveBox service itself
  # ** declares, so the backup follows the service if that data
  # ** directory moves.
  #
  # ** Destination and staging directories are registered under
  # ** darwin.backups.perContainer in options/paths.nix and resolved by
  # ** the helper from appSlug. Change them there, not here.
  archiveboxSourceDir = config.services.archivebox.dataDir;

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "archivebox";
  preserveSymlinks = true;
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "ArchiveBox";
  appSlug = "archivebox";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent runOnRebuild extraExcludePatterns;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  sourceDir = archiveboxSourceDir;
  scheduledHour = 1;
  scheduledMinute = 0;

  prepareArchive = ''
    staging_dir="$(
      ${pkgs.coreutils}/bin/mktemp -d "${paths.darwin.backups.lockRoot}/${appSlug}-backup.XXXXXX"
    )"
    archive_source_parent="$staging_dir"
    archive_source_name="$source_name"
    staged_source="$staging_dir/$source_name"

    ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"
    ${pkgs.rsync}/bin/rsync -a "''${exclude_args[@]}" \
      --exclude='index.sqlite3' \
      --exclude='index.sqlite3-shm' \
      --exclude='index.sqlite3-wal' \
      -- "$source_dir/" "$staged_source/"

    if [ ! -f "$source_dir/index.sqlite3" ]; then
      fail "ArchiveBox SQLite database does not exist: $source_dir/index.sqlite3"
    fi

    ${pkgs.coreutils}/bin/timeout 300 \
      ${pkgs.sqlite}/bin/sqlite3 \
      "$source_dir/index.sqlite3" \
      ".backup '$staged_source/index.sqlite3'"
  '';
}
