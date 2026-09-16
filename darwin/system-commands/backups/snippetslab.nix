# darwin/system-commands/backups/snippetslab.nix
# SnippetsLab backup command: `snippetslab-backup`.

{ paths, ... }:

{
  services.backups.apps.snippetslab = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "SnippetsLab";

    # ---- PATHS ---- #

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "snippetslab" ];

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportSources = {
      applicationSupportPaths = [
        {
          sourcePath = "${paths.darwin.library.containers}/com.renfei.SnippetsLab/Data/Library/Application Support/Markdown Themes";
          destinationPath = "assets/markdown-themes";
        }
        {
          sourcePath = "${paths.darwin.library.containers}/com.renfei.SnippetsLab/Data/Library/Application Support/Themes";
          destinationPath = "assets/themes";
        }
      ];

      excludePatterns = [ ];
    };

    applicationPreferences = {
      preferencePaths = [
        {
          sourcePath = "${paths.darwin.library.containers}/com.renfei.SnippetsLab/Data/Library/Preferences/com.renfei.SnippetsLab.plist";
          destinationPath = "com.renfei.SnippetsLab.plist";
        }
      ];

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
    archivePrefix = "snippetslab";
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
