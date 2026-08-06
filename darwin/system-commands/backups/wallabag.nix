# darwin/system-commands/backups/wallabag.nix
#
# Backs up Wallabag container data to SystemBackup.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ---- EDITABLE BACKUP PATHS
  backupPaths = config.services.containerBackups.paths;
  wallabagSourceDir = "${backupPaths.containerDirectory}/wallabag";
  backupDestinationDir = "${backupPaths.externalBackupVolume}/data-backups/container-backups/wallabag";
  localStagingDir = "${backupPaths.downloadsDirectory}/backup-staging/wallabag";

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
  archivePrefix = "wallabag";
  preserveSymlinks = true;
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Wallabag";
  appSlug = "wallabag";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent runOnRebuild extraExcludePatterns;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  sourceDir = wallabagSourceDir;
  destinationDir = backupDestinationDir;
  inherit localStagingDir;
  scheduledHour = 5;
  scheduledMinute = 0;
}
