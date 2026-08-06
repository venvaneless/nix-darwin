# darwin/system-commands/backups/better-finder-renamer.nix
# A Better Finder Rename backup command: `better-renamer-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # ---- EDITABLE BACKUP PATHS
  applicationSupportEntries = [
    {
      relativePath = "A Better Finder Rename 12";
      destinationPath = "app-support/A Better Finder Rename 12";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "ABFR Registration";
      destinationPath = "app-pref/ABFR Registration";
    }
    {
      relativePath = "net.publicspace.abfr12.plist";
      destinationPath = "app-pref/net.publicspace.abfr12.plist";
    }
  ];
  configEntries = [
    # { relativePath = "better-finder-renamer"; destinationPath = "user-config/better-finder-renamer"; }
  ];
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Better Finder Rename";
    #   destinationPath = "additional/Somewhere/Better Finder Rename";
    # }
  ];

  # ---- EDITABLE EXCLUSIONS
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];

  # ---- INDIVIDUAL BACKUP CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "better-finder-renamer";
  preserveSymlinks = true;

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
in
appBackupHelper.mkAppBackup {
  inherit config;

  appName = "A Better Finder Rename";
  appSlug = "better-finder-renamer";
  commandName = "better-renamer-backup";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent;
  inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
  applicationSupportRoot = applicationSupportDirectory;
  preferencesRoot = preferencesDirectory;
  configRoot = configDirectory;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
}
