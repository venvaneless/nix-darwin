# darwin/system-commands/backups/better-finder-attributes.nix
# A Better Finder Attributes backup command: `better-attributes-backup`.

{ paths, ... }:

{
  services.backups.apps.better-finder-attributes = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "A Better Finder Attributes";
    commandName = "better-attributes-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "better-finder-attributes" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "A Better Finder Attributes 7";
          destinationPath = "app-support/A Better Finder Attributes 7";
        }
      ];

      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "net.publicspace.abfa7.plist";
          destinationPath = "net.publicspace.abfa7.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [ ];

      excludePatterns = [ ];
    };

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Better Finder Attributes";
        #   destinationPath = "additional/Somewhere/Better Finder Attributes";
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
    archivePrefix = "better-finder-attributes";

    /* iCloud */
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    # ---- BACKUP CONTROLS
    automatic = false;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    transferLimitKiBps = 4096;

    /* Encryption */
    encrypt = false;
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
