# darwin/system-commands/backups/wezterm.nix
# WezTerm backup command: `wezterm-backup`.

{ paths, ... }:

{
  services.backups.apps.wezterm = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "WezTerm";
    commandName = "wezterm-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.terminal;
    destinationSegments = [ "wezterm" "backups" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "wezterm";
          destinationPath = "app-support/wezterm";
        }
      ];

      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.github.wez.wezterm.plist";
          destinationPath = "com.github.wez.wezterm.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [
        {
          sourcePath = "wezterm";
          destinationPath = "config/wezterm";
        }
      ];

      excludePatterns = [ ];
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
    archivePrefix = "wezterm";
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
