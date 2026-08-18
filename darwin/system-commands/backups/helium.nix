# darwin/system-commands/backups/helium.nix
# Helium browser backup command: `helium-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # ---- EDITABLE BACKUP PATHS
  # Browser-specific mutable locations come from the centralized paths.
  paths = import ../../../options/paths.nix { };
  browserPaths = paths.darwin.home.browsers;

  destinationSegments = [ "helium" ];
  applicationSupportEntries = [
    { relativePath = "net.imput.helium"; destinationPath = "app-support/net.imput.helium"; }
  ];
  preferenceEntries = [
    { relativePath = "net.imput.helium.plist"; destinationPath = "app-pref/net.imput.helium.plist"; }
  ];
  configEntries = [
    # { relativePath = "helium"; destinationPath = "user-config/helium"; }
  ];
  additionalSources = [
    {
      sourcePath = browserPaths.heliumExtensions;
      destinationPath = "profile/helium-extensions";
    }
    {
      sourcePath = browserPaths.heliumProfile;
      destinationPath = "profile/helium-ven";
    }
  ];
  extraExcludePatterns = [ "sockets/" "private/socket" "*.sock" ];

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  showProgress = true;
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "helium";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  heliumBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Helium";
    appSlug = "helium";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    destinationRoot = "browserBackups";
    inherit destinationSegments applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
  };
in
heliumBackup
