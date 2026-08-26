# darwin/system-commands/backups/paste.nix
# Paste backup command: `paste-backup`.

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
      relativePath = "com.wiheads.paste-direct";
      destinationPath = "app-support/com.wiheads.paste-direct";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.wiheads.paste-direct.plist";
      destinationPath = "app-pref/com.wiheads.paste-direct.plist";
    }
  ];
  configEntries = [
    # { relativePath = "paste"; destinationPath = "user-config/paste"; }
  ];
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Paste";
    #   destinationPath = "additional/Somewhere/Paste";
    # }
  ];

  # ---- EDITABLE EXCLUSIONS
  # Add folders or file patterns that Paste should not include.
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];

  # ---- INDIVIDUAL ARCHIVE CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "paste";
  preserveSymlinks = true;

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  showProgress = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  pasteBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Paste";
    appSlug = "paste";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
  };
in
pasteBackup
