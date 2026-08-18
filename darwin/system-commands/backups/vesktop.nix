# darwin/system-commands/backups/vesktop.nix
# Vesktop backup command: `vesktop-backup`.

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
      relativePath = "vesktop";
      destinationPath = "app-support/vesktop";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "dev.vencord.vesktop.plist";
      destinationPath = "app-pref/dev.vencord.vesktop.plist";
    }
  ];
  configEntries = [
    # { relativePath = "vesktop"; destinationPath = "user-config/vesktop"; }
  ];
  additionalSources = [ ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "vesktop";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  vesktopBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Vesktop";
    appSlug = "vesktop";
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
vesktopBackup
