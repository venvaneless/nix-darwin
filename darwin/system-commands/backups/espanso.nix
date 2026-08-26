# darwin/system-commands/backups/espanso.nix
# Espanso backup command: `espanso-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # ---- EDITABLE BACKUP CONTENTS
  configEntries = [
    {
      relativePath = "espanso";
      destinationPath = "user-config/espanso";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.federicoterzi.espanso.plist";
      destinationPath = "app-pref/com.federicoterzi.espanso.plist";
    }
  ];
  additionalSources = [ ];

  # ---- EDITABLE EXCLUSIONS
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  showProgress = true;

  # ---- INDIVIDUAL ARCHIVE CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "espanso";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  espansoBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Espanso";
    appSlug = "espanso";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    inherit configEntries preferenceEntries additionalSources extraExcludePatterns;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
  };
in
espansoBackup
