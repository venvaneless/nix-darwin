# darwin/system-commands/backups/raycast.nix
# Raycast backup command: `raycast-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  backupPaths = config.services.appBackups.paths;
  applicationSupportDirectory = backupPaths.applicationSupportDirectory;
  preferencesDirectory = backupPaths.preferencesDirectory;
  configDirectory = backupPaths.configDirectory;

  # ---- EDITABLE BACKUP CONTENTS
  applicationSupportEntries = [
    {
      relativePath = "com.raycast.macos";
      destinationPath = "app-support/com.raycast.macos";
      # Raycast re-downloads these extension and runtime files. The durable
      # settings database remains included without their large duplicate tree.
      excludePatterns = [
        "NodeJS/"
        "RaycastWrapped/"
        "extensions/"
        "posthog.replayFolder/"
        "*.sqlite-shm"
        "*.sqlite-wal"
      ];
    }
    {
      relativePath = "com.raycast-x.macos";
      destinationPath = "app-support/com.raycast-x.macos";
      # Indexes, installed extensions, and live database sidecars are rebuilt
      # by Raycast. Keep the primary settings databases only.
      excludePatterns = [
        "extensions/"
        "index/"
        "node/"
        "SingleInstance.lock"
        "*.db-shm"
        "*.db-wal"
      ];
    }
    {
      relativePath = "com.raycast.shared";
      destinationPath = "app-support/com.raycast.shared";
      excludePatterns = [
        "*.lock"
        "*/pid"
      ];
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.raycast.macos.plist";
      destinationPath = "app-pref/com.raycast.macos.plist";
    }
    {
      relativePath = "com.raycast-x.macos.plist";
      destinationPath = "app-pref/com.raycast-x.macos.plist";
    }
  ];
  configEntries = [
    {
      relativePath = "raycast";
      destinationPath = "user-config/raycast";
      # Marketplace extension bundles are duplicated in Application Support
      # and are reinstalled by Raycast; retain the actual configuration only.
      excludePatterns = [ "extensions/" ];
    }
    {
      relativePath = "raycast-x";
      destinationPath = "user-config/raycast-x";
      # Keep editable script commands, but skip generated Node bytecode and
      # the marketplace extension mirror that makes manual backups expensive.
      excludePatterns = [
        "node-compile-cache/"
        "extensions/"
      ];
    }
  ];

  # ---- EDITABLE EXCLUSIONS
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
  # Raycast has many extension files, so manual runs need a lower CPU and I/O
  # ceiling as well as the background scheduling safeguards.
  cpuLimitPercent = 10;
  transferLimitKiBps = 4096;
  showProgress = true;

  # ---- INDIVIDUAL ARCHIVE CONTROLS
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
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent transferLimitKiBps showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    inherit applicationSupportEntries preferenceEntries configEntries additionalSources extraExcludePatterns;
    applicationSupportRoot = applicationSupportDirectory;
    preferencesRoot = preferencesDirectory;
    configRoot = configDirectory;
    requiredAny = [ [
      "${applicationSupportDirectory}/com.raycast.macos"
      "${applicationSupportDirectory}/com.raycast-x.macos"
    ] ];
  };
in
raycastBackup
