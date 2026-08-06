# darwin/system-commands/backups/wezterm.nix
# WezTerm backup command: `wezterm-backup`.

{ config, lib, pkgs, ... }:

let
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
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  weztermBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "WezTerm";
    appSlug = "wezterm";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "wezterm";
    preserveSymlinks = true;
    destinationRoot = "terminalBackups";
    inherit destinationSegments applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
  };
in
weztermBackup
