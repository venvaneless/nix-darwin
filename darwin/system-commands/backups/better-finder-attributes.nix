# darwin/system-commands/backups/better-finder-attributes.nix
# A Better Finder Attributes backup command: `better-attributes-backup`.

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
      relativePath = "A Better Finder Attributes 7";
      destinationPath = "app-support/A Better Finder Attributes 7";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "net.publicspace.abfa7.plist";
      destinationPath = "app-pref/net.publicspace.abfa7.plist";
    }
  ];
  configEntries = [
    # { relativePath = "better-finder-attributes"; destinationPath = "user-config/better-finder-attributes"; }
  ];
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Better Finder Attributes";
    #   destinationPath = "additional/Somewhere/Better Finder Attributes";
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
  archivePrefix = "better-finder-attributes";
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

  appName = "A Better Finder Attributes";
  appSlug = "better-finder-attributes";
  commandName = "better-attributes-backup";
  inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent;
  inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
  applicationSupportRoot = applicationSupportDirectory;
  preferencesRoot = preferencesDirectory;
  configRoot = configDirectory;
  inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
}
