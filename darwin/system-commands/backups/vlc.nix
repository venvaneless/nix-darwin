# darwin/system-commands/backups/vlc.nix
# VLC backup command: `vlc-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP PATHS
  applicationSupportEntries = [
    { relativePath = "org.videolan.vlc"; destinationPath = "app-support/org.videolan.vlc"; }
  ];
  preferenceEntries = [
    { relativePath = "org.videolan.vlc"; destinationPath = "app-pref/org.videolan.vlc"; }
    { relativePath = "org.videolan.vlc.plist"; destinationPath = "app-pref/org.videolan.vlc.plist"; }
  ];
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];
  additionalSources = [ ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "vlc";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  vlcBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "VLC";
    appSlug = "vlc";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
    inherit applicationSupportEntries preferenceEntries additionalSources extraExcludePatterns;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
vlcBackup
