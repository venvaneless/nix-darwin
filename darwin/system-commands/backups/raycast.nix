# darwin/system-commands/backups/raycast.nix
# Raycast backup command: `raycast-backup`.

{ paths, ... }:

{
  services.backups.apps.raycast = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Raycast";
    commandName = "raycast-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "raycast" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "com.raycast.macos";
          destinationPath = "app-support/com.raycast.macos";
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
          sourcePath = "com.raycast-x.macos";
          destinationPath = "app-support/com.raycast-x.macos";
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
          sourcePath = "com.raycast.shared";
          destinationPath = "app-support/com.raycast.shared";
          excludePatterns = [
            "*.lock"
            "*/pid"
          ];
        }
      ];

      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.raycast.macos.plist";
          destinationPath = "pref/com.raycast.macos.plist";
        }
        {
          sourcePath = "com.raycast-x.macos.plist";
          destinationPath = "pref/com.raycast-x.macos.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [
        {
          sourcePath = "raycast";
          destinationPath = "config/raycast";
        }
        {
          sourcePath = "raycast-x";
          destinationPath = "config/raycast-x";
          excludePatterns = [
            "node-compile-cache/"
          ];
        }
      ];

      excludePatterns = [
        "extensions/"
      ];
    };

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/App";
        #   destinationPath = "";
        # }
      ];

      excludePatterns = [ ];
    };

    requiredAny = [ [
        "${paths.darwin.library.applicationSupport}/com.raycast.macos"
        "${paths.darwin.library.applicationSupport}/com.raycast-x.macos"
      ] ];

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "raycast";
    preserveSymlinks = true;

    # ---- ENCRYPTION
    # The public key comes from the identity file on every run.
    encrypt = false;
    encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;

    # ---- ICLOUD
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 10;
    transferLimitKiBps = 4096;

    # ---- OUTPUT
    showProgress = true;

    # ---- PROCESS PRIORITY
    processType = "Background";
    niceLevel = 20;
    lowPriorityIO = true;

    # ---- LOGS
    logDirectory = paths.darwin.backups.logs;
    logFilenameTemplate = "{appSlug}-{timestamp}.log";
    errorLogFilenameTemplate = "{appSlug}-{timestamp}-error.log";
    logTimestampFormat = "%Y-%m-%d-%H-%M-%S";
    logOnlyOnErrors = true;
  };
}
