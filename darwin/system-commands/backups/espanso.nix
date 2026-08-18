# darwin/system-commands/backups/espanso.nix
# Espanso backup command: `espanso-backup`.

{ config, lib, pkgs, ... }:

let
  configEntries = [
    { relativePath = "espanso"; destinationPath = "user-config/espanso"; }
  ];
  preferenceEntries = [
    { relativePath = "com.federicoterzi.espanso.plist"; destinationPath = "app-pref/com.federicoterzi.espanso.plist"; }
  ];
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];
  additionalSources = [ ];
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "espanso";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  espansoBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Espanso";
    appSlug = "espanso";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
    inherit configEntries preferenceEntries additionalSources extraExcludePatterns;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
espansoBackup
