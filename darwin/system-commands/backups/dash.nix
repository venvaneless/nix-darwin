# darwin/system-commands/backups/dash.nix
# Dash backup command: `dash-backup`.

{ paths, ... }:

{
  services.backups.apps.dash = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Dash";
    commandName = "dash-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "dash" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "Dash";
          destinationPath = "app-support/Dash";

          # Docsets and generated output are re-downloaded by Dash.
          excludePatterns = [
            "DocSets/"
            "Docset Generator/"
          ];
        }
        {
          sourcePath = "com.kapeli.dash-setapp";
          destinationPath = "app-support/com.kapeli.dash-setapp";
        }
      ];

      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.kapeli.dashdoc.plist";
          destinationPath = "pref/com.kapeli.dashdoc.plist";
        }
        {
          sourcePath = "com.kapeli.dash-setapp.plist";
          destinationPath = "pref/com.kapeli.dash-setapp.plist";
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
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Dash";
        #   destinationPath = "additional/Somewhere/Dash";
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
    archivePrefix = "dash";
    preserveSymlinks = true;

    # ---- ICLOUD
    storeiCloud = false;
    keepiCloudBackup = true;
    iCloudBackupsToKeep = 3;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
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
