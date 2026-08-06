# darwin/system-commands/backups/karakeep.nix
#
# =====================================================================
# KARAKEEP CONTAINER BACKUP
#
# Creates a daily, low-priority backup only when Karakeep data changed.
# The archive is built and verified locally before moving to SystemBackup.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ---- EDITABLE BACKUP PATHS
  containerConfig = [
    {
      sourcePath = "/Users/ven/.config/containers/karakeep";
      destinationPath = "karakeep";
    }
  ];

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
  archivePrefix = "karakeep";
  preserveSymlinks = true;
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Karakeep";
  appSlug = "karakeep";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent runOnRebuild extraExcludePatterns;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  inherit containerConfig;
  scheduledHour = 6;
  scheduledMinute = 0;
}
