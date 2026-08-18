# darwin/system-commands/backups/dash.nix
# Dash backup command: `dash-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP CONTENTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # These entries resolve from applicationSupportDirectory. Add one entry for
  # every Dash path stored in Application Support.
  applicationSupportEntries = [
    {
      relativePath = "Dash";
      destinationPath = "app-support/Dash";
    }
    {
      relativePath = "com.kapeli.dash-setapp";
      destinationPath = "app-support/com.kapeli.dash-setapp";
    }
  ];
  # These entries resolve from preferencesDirectory. Add one entry for every
  # Dash preference file or directory that should be backed up.
  preferenceEntries = [
    {
      relativePath = "com.kapeli.dashdoc.plist";
      destinationPath = "app-pref/com.kapeli.dashdoc.plist";
    }
    {
      relativePath = "com.kapeli.dash-setapp.plist";
      destinationPath = "app-pref/com.kapeli.dash-setapp.plist";
    }
  ];
  configEntries = [
    # { relativePath = "dash"; destinationPath = "user-config/dash"; }
  ];
  # Use this list for any additional absolute source outside the standard
  # roots above; every item is copied to its own destinationPath.
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Dash";
    #   destinationPath = "additional/Somewhere/Dash";
    # }
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
  archivePrefix = "dash";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  dashBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Dash";
    appSlug = "dash";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
    inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
dashBackup
