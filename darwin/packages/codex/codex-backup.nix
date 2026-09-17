# darwin/packages/codex/codex-backup.nix
# Codex backup command: `codex-backup`.

{ paths, ... }:

{
  services.backups.apps.codex = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Codex";
    commandName = "codex-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.containers;
    destinationSegments = [ "codex" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [ ];

      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.openai.codex.plist";
          destinationPath = "com.openai.codex.plist";
        }
      ];

      excludePatterns = [ ];
    };

    # ** Each part lands at the same relative path in the archive root, so
    # ** extracting the archive into ~/.config/codex restores it.
    configEntries = {
      configPaths = [
        {
          sourcePath = "codex/chatgpt";
          destinationPath = "chatgpt";
        }
        {
          sourcePath = "codex/api";
          destinationPath = "api";
        }
        {
          sourcePath = "codex/shared";
          destinationPath = "shared";
        }
        {
          sourcePath = "codex/backups";
          destinationPath = "backups";
        }
      ];

      excludePatterns = [
        "*.sock"
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

    requiredAny = [ ];

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "codex";

    /* iCloud */
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    # ---- BACKUP CONTROLS
    automatic = true;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 28800;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 10;
    transferLimitKiBps = 4096;

    /* Encryption */
    encrypt = true;
    encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;
    # The public key comes from the identity file on every run

    # ---- BACKUP ARCHITECTURE
    preserveSymlinks = true;

    /* Backup Process */
    showProgress = true;
    processType = "Background";
    niceLevel = 20;
    lowPriorityIO = true;

    /* Logs */
    logDirectory = paths.darwin.backups.logs;
    logFilenameTemplate = "{appSlug}-{timestamp}.log";
    errorLogFilenameTemplate = "{appSlug}-{timestamp}-error.log";
    logTimestampFormat = "%Y-%m-%d-%H-%M-%S";
    logOnlyOnErrors = true;
  };
}
