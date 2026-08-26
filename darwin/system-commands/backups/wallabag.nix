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
  # ---- BACKUP PATHS
  # ** The source is the directory the Wallabag service itself declares,
  # ** so the backup follows the service if that data directory moves.
  #
  # ** Destination and staging directories are registered under
  # ** darwin.backups.perContainer in options/paths.nix and resolved by
  # ** the helper from appSlug. Change them there, not here.
  wallabagSourceDir = config.services.wallabag.dataDir;

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
  archivePrefix = "wallabag";
  preserveSymlinks = true;
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Wallabag";
  appSlug = "wallabag";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress runOnRebuild additionalSources extraExcludePatterns;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  sourceDir = wallabagSourceDir;
  scheduledHour = 5;
  scheduledMinute = 0;
}
