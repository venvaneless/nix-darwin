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
    commandName = "snippetslab-backup";

    # ---- PATHS ---- #

    # -- Application Support
    # ** SnippetsLab is sandboxed, so its Library lives in its container.
    applicationSupportRoot = "${paths.darwin.library.containers}/com.renfei.SnippetsLab/Data/Library/Application Support";

    # -- Preferences
    preferencesRoot = "${paths.darwin.library.containers}/com.renfei.SnippetsLab/Data/Library/Preferences";

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "snippetslab" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "Markdown Themes";
          destinationPath = "assets/markdown-themes";
        }
        {
          sourcePath = "Themes";
          destinationPath = "assets/themes";
        }
      ];

      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.renfei.SnippetsLab.plist";
          destinationPath = "com.renfei.SnippetsLab.plist";
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
    archivePrefix = "snippetslab";
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
