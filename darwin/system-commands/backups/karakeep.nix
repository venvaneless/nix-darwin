# darwin/system-commands/backups/karakeep.nix
# Karakeep container backup command: `karakeep-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.containerBackups.paths;
  containerDirectory = backupPaths.containerDirectory;
  # ** Destination and staging directories are registered under
  # ** darwin.backups.perContainer in options/paths.nix and resolved by
  # ** the helper from appSlug. Change them there, not here.

  # ---- EDITABLE BACKUP PATHS
  # These entries resolve from containerDirectory. Add every Karakeep data
  # directory or file that should be included in the same backup.
  containerEntries = [
    {
      relativePath = "karakeep";
      destinationPath = "karakeep";
    }
  ];
  # Add absolute sources outside containerDirectory here.
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Karakeep";
    #   destinationPath = "additional/Somewhere/Karakeep";
    # }
  ];
  sourceEntries = containerEntries ++ additionalSources;

  # ---- EDITABLE EXCLUSIONS
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];

  # ---- INDIVIDUAL BACKUP CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "karakeep";
  preserveSymlinks = true;

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;
  scheduledHour = 6;
  scheduledMinute = 0;

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Karakeep";
  appSlug = "karakeep";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent runOnRebuild;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  inherit sourceEntries extraExcludePatterns;
  sourceRoot = containerDirectory;
  inherit scheduledHour scheduledMinute;
}
