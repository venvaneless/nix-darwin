# darwin/system-commands/backups/pearcleaner.nix
# Pearcleaner backup command: `pearcleaner-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # macOS Library roots come from the centralized path definitions.
  paths = import ../../../options/paths.nix { };
  libraryPaths = paths.darwin.library;

  applicationSupportSources = [
    {
      sourcePath = "${libraryPaths.applicationSupport}/Pearcleaner";
      destinationPath = "Pearcleaner";
    }
  ];
  applicationPreferences = [
    {
      sourcePath = "${libraryPaths.preferences}/com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/com.alienator88.Pearcleaner.plist";
    }
    {
      sourcePath = "${libraryPaths.preferences}/group.com.alienator88.Pearcleaner.plist";
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
