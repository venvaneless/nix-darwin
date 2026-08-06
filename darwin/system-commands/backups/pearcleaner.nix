# darwin/system-commands/backups/pearcleaner.nix
# Pearcleaner backup command: `pearcleaner-backup`.

{ config, lib, pkgs, ... }:

let
  applicationSupportSources = [
    {
      sourcePath = "/Users/ven/Library/Application Support/Pearcleaner";
      destinationPath = "Pearcleaner";
    }
  ];
  applicationPreferences = [
    {
      sourcePath = "/Users/ven/Library/Preferences/com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/com.alienator88.Pearcleaner.plist";
    }
    {
      sourcePath = "/Users/ven/Library/Preferences/group.com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/group.com.alienator88.Pearcleaner.plist";
    }
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
    inherit applicationSupportSources applicationPreferences additionalSources;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
pearcleanerBackup
