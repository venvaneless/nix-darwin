# darwin/system-commands/backups/browsertrix.nix
# Browsertrix container backup command: `browsertrix-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  # ** Destination and staging directories are registered under
  # ** darwin.backups.perContainer in options/paths.nix and resolved by
  # ** the helper from appSlug. Change them there, not here.
  backupPaths = config.services.containerBackups.paths;
  containerDirectory = backupPaths.containerDirectory;

  # ---- EDITABLE BACKUP PATHS
  # These entries resolve from containerDirectory. Add as many Browsertrix
  # directories or files as required, each with its archive destination.
  containerEntries = [
    {
      relativePath = "browsertrix";
      destinationPath = "browsertrix";
    }
  ];
  # Use absolute sourcePath entries for data outside containerDirectory.
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Browsertrix";
    #   destinationPath = "additional/Somewhere/Browsertrix";
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
  archivePrefix = "browsertrix";
  preserveSymlinks = true;

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;

  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Browsertrix";
  appSlug = "browsertrix";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent runOnRebuild;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  inherit sourceEntries extraExcludePatterns;
  sourceRoot = containerDirectory;
  scheduledHour = 2;
  scheduledMinute = 0;
}
