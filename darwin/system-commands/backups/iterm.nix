# darwin/system-commands/backups/iterm.nix
# iTerm2 backup command: `iterm-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP CONTENTS
  destinationSegments = [ "iterm" "backups" ];
  applicationSupportEntries = [
    {
      relativePath = "iTerm2";
      destinationPath = "app-support/iTerm2";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.googlecode.iterm2.plist";
      destinationPath = "app-pref/com.googlecode.iterm2.plist";
    }
  ];
  additionalSources = [
    # { sourcePath = "/Users/ven/Library/Somewhere/iTerm2"; destinationPath = "additional/iTerm2"; }
  ];
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  itermBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "iTerm2";
    appSlug = "iterm";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "iterm";
    preserveSymlinks = true;
    destinationRoot = "terminalBackups";
    inherit destinationSegments applicationSupportEntries preferenceEntries additionalSources;
    extraExcludePatterns = [
      "sockets/"
      "private/socket"
      "*.sock"
    ];
  };
in
itermBackup
