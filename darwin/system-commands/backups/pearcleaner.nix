# darwin/system-commands/backups/pearcleaner.nix
# Pearcleaner backup command: `pearcleaner-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # ---- EDITABLE BACKUP CONTENTS
  applicationSupportEntries = [
    {
      relativePath = "Pearcleaner";
      destinationPath = "app-support/Pearcleaner";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/com.alienator88.Pearcleaner.plist";
    }
    {
      relativePath = "group.com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/group.com.alienator88.Pearcleaner.plist";
    }
  ];
  configEntries = [
    # { relativePath = "pearcleaner"; destinationPath = "user-config/pearcleaner"; }
  ];
  additionalSources = [ ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "pearcleaner";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  pearcleanerBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Pearcleaner";
    appSlug = "pearcleaner";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
    inherit applicationSupportEntries preferenceEntries configEntries additionalSources;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
pearcleanerBackup
