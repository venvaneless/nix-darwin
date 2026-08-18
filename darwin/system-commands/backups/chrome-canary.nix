# darwin/system-commands/backups/chrome-canary.nix
# Chrome Canary browser backup command: `chrome-canary-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP CONTENTS
  destinationSegments = [ "chrome-canary" ];
  applicationSupportEntries = [
    {
      relativePath = "Google/Chrome Canary";
      destinationPath = "app-support/Google/Chrome Canary";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.google.Chrome.canary.plist";
      destinationPath = "app-pref/com.google.Chrome.canary.plist";
    }
  ];
  additionalSources = [
    # { sourcePath = "/Users/ven/Library/Somewhere/Chrome Canary"; destinationPath = "additional/Chrome Canary"; }
  ];
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "chrome-canary";
  preserveSymlinks = true;
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  chromeCanaryBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Chrome Canary";
    appSlug = "chrome-canary";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
    destinationRoot = "browserBackups";
    inherit destinationSegments applicationSupportEntries preferenceEntries additionalSources extraExcludePatterns;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
chromeCanaryBackup
