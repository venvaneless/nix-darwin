# darwin/system-commands/backups/iterm.nix
# iTerm2 backup command: `iterm-backup`.

{ paths, ... }:

{
  services.backups.apps.iterm = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "iTerm2";
    commandName = "iterm-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.terminal;

    destinationSegments = [
      "iterm"
      "backups"
    ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "iTerm2";
          destinationPath = "app-support/iTerm2";
        }
      ];

      # Sockets, lock files, and window state the running app leaves behind.
      excludePatterns = [
        "sockets/"
        "private/socket"
        "*.sock"
        "*.socket"
        "*.socket.lock"
        "*-lock"
        "SavedState/"
        "*.sqlite-shm"
        "*.sqlite-wal"
      ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.googlecode.iterm2.plist";
          destinationPath = "com.googlecode.iterm2.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [
        {
          sourcePath = "iterm2/sessions";
          destinationPath = "config/iterm2/sessions";
        }
      ];

      # Sockets and lock files the running daemon leaves behind.
      excludePatterns = [
        "sockets/"
        "private/socket"
        "*.sock"
        "*.socket"
        "*.socket.lock"
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
    archivePrefix = "iterm";

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
