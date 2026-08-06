# darwin/system-commands/backups/librewolf.nix
# LibreWolf browser backup command: `librewolf-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP CONTENTS
  destinationSegments = [ "librewolf" ];
  applicationSupportEntries = [
    { relativePath = "librewolf"; destinationPath = "app-support/librewolf"; }
  ];
  preferenceEntries = [
    { relativePath = "net.librewolf.librewolf.plist"; destinationPath = "app-pref/net.librewolf.librewolf.plist"; }
    { relativePath = "org.mozilla.librewolf.plist"; destinationPath = "app-pref/org.mozilla.librewolf.plist"; }
  ];
  additionalSources = [
    # { sourcePath = "/Users/ven/Library/Somewhere/LibreWolf"; destinationPath = "additional/LibreWolf"; }
  ];
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "librewolf";
  preserveSymlinks = true;
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  librewolfBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "LibreWolf";
    appSlug = "librewolf";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    destinationRoot = "browserBackups";
    inherit destinationSegments applicationSupportEntries preferenceEntries additionalSources extraExcludePatterns;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
librewolfBackup
