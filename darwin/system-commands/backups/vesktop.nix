# darwin/system-commands/backups/vesktop.nix
# Vesktop backup command: `vesktop-backup`.

{ paths, ... }:

{
  services.backups.apps.vesktop = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Vesktop";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "vesktop" ];

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    # ** Plugins ship inside Vencord's downloaded bundle, so only their
    # ** settings and stored data are kept. Login token (Local Storage,
    # ** Cookies) is deliberately left out.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          # Vesktop app settings
          sourcePath = "vesktop/settings.json";
          destinationPath = "settings.json";
        }
        {
          # Window size and position
          sourcePath = "vesktop/state.json";
          destinationPath = "state.json";
        }
        {
          # Vencord plugin toggles, plugin options, QuickCSS
          sourcePath = "vesktop/settings";
          destinationPath = "settings";
        }
        {
          sourcePath = "vesktop/themes";
          destinationPath = "themes";
        }
        {
          # Plugin data (Vencord DataStore)
          sourcePath = "vesktop/sessionData/IndexedDB";
          destinationPath = "sessionData/IndexedDB";
        }
      ];

      excludePatterns = [
        # Rewritten constantly while the app runs.
        "LOCK"
      ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "dev.vencord.vesktop.plist";
          destinationPath = "dev.vencord.vesktop.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [ ];

      excludePatterns = [ ];
    };

    # Absolute paths outside the roots above. Uncomment to add one.

    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/App";
        #   destinationPath = "";
        # }
      ];

      excludePatterns = [ ];
    };

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "vesktop";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
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
  };
}
