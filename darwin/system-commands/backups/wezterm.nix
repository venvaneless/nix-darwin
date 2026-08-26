# darwin/system-commands/backups/wezterm.nix
# WezTerm backup command: `wezterm-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # ---- EDITABLE BACKUP CONTENTS
  destinationSegments = [ "wezterm" "backups" ];
  applicationSupportEntries = [
    {
      relativePath = "wezterm";
      destinationPath = "app-support/wezterm";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.github.wez.wezterm.plist";
      destinationPath = "app-pref/com.github.wez.wezterm.plist";
    }
  ];
  configEntries = [
    {
      relativePath = "wezterm";
      destinationPath = "user-config/wezterm";
    }
  ];
  additionalSources = [
    # { sourcePath = "/Users/ven/Library/Somewhere/WezTerm"; destinationPath = "additional/WezTerm"; }
  ];
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
  archivePrefix = "wezterm";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  weztermBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "WezTerm";
    appSlug = "wezterm";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    destinationRoot = "terminalBackups";
    inherit destinationSegments applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
  };
in
weztermBackup
