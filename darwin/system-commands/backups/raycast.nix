# darwin/system-commands/backups/raycast.nix
# Raycast backup command: `raycast-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # macOS Library roots come from the centralized path definitions.
  paths = import ../../../options/paths.nix { };
  libraryPaths = paths.darwin.library;

  # ---- EDITABLE BACKUP PATHS
  applicationSupportEntries = [
    {
      relativePath = "com.raycast.macos";
      destinationPath = "app-support/com.raycast.macos";
    }
    {
      relativePath = "com.raycast-x.macos";
      destinationPath = "app-support/com.raycast-x.macos";
    }
    {
      relativePath = "com.raycast.shared";
      destinationPath = "app-support/com.raycast.shared";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.raycast.macos.plist";
      destinationPath = "app-pref/com.raycast.macos.plist";
    }
  ];
  configEntries = [
    {
      relativePath = "raycast";
      destinationPath = "user-config/raycast";
    }
  ];
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];
  additionalSources = [ ];

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "raycast";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  raycastBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Raycast";
    appSlug = "raycast";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    requiredAny = [ [
      "${libraryPaths.applicationSupport}/com.raycast.macos"
      "${libraryPaths.applicationSupport}/com.raycast-x.macos"
    ] ];
  };
in
raycastBackup
