# darwin/system-commands/backups/vesktop.nix
# Vesktop backup command: `vesktop-backup`.

{ config, lib, pkgs, ... }:

let
  applicationSupportSources = [
    {
      sourcePath = "/Users/ven/Library/Application Support/vesktop";
      destinationPath = "vesktop";
    }
  ];
  applicationPreferences = [
    {
      sourcePath = "/Users/ven/Library/Preferences/dev.vencord.vesktop.plist";
      destinationPath = "dev.vencord.vesktop.plist";
    }
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
    inherit applicationSupportSources applicationPreferences additionalSources;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
vesktopBackup
