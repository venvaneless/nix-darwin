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
    archivePrefix = "iterm";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
  };
}
