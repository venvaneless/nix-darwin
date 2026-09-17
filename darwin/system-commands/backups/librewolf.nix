# darwin/system-commands/backups/librewolf.nix
# LibreWolf browser backup command: `librewolf-backup`.

{ paths, ... }:

{
  services.backups.apps.librewolf = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "LibreWolf";
    commandName = "librewolf-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.browsers;
    destinationSegments = [ "librewolf" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    # ** LibreWolf keeps its data in the profile below, not in
    # ** Application Support, so nothing is taken from there.
    applicationSupportEntries = {
      applicationSupportPaths = [ ];
      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "org.nixos.librewolf.plist";
          destinationPath = "org.nixos.librewolf.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [
        {
          sourcePath = "browsers/firefox-ven";
          destinationPath = "config/browsers/firefox-ven";
        }
      ];

      excludePatterns = [
        # Firefox rebuilds all of these on the next start.
        "cache2/"
        "startupCache/"
        "shader-cache/"
        "thumbnails/"
        "safebrowsing/"
        "storage/temporary/"
        "crashes/"
        "minidumps/"
        "datareporting/"
        "saved-telemetry-pings/"
        "*.log"

        # Rewritten constantly while the browser runs.
        "lock"
        ".parentlock"
        "*.sqlite-wal"
        "*.sqlite-shm"
        "*.sqlite-journal"
      ];
    };

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/LibreWolf";
        #   destinationPath = "additional/Somewhere/LibreWolf";
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
    archivePrefix = "librewolf";
    preserveSymlinks = true;

    # ---- ENCRYPTION
    # The public key comes from the identity file on every run.
    encrypt = true;
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
