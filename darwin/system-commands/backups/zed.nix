# darwin/system-commands/backups/zed.nix
# Zed backup command: `zed-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP CONTENTS
  applicationSupportEntries = [ { relativePath = "zed"; destinationPath = "app-support/zed"; } ];
  preferenceEntries = [ { relativePath = "dev.zed.Zed.plist"; destinationPath = "app-pref/dev.zed.Zed.plist"; } ];
  configEntries = [ { relativePath = "zed"; destinationPath = "user-config/zed"; } ];
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];
  additionalSources = [ ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "zed";
  preserveSymlinks = true;
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  zedBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Zed";
    appSlug = "zed";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
zedBackup
