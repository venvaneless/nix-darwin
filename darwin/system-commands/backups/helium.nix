# darwin/system-commands/backups/helium.nix
# Helium browser backup command: `helium-backup`.

{ paths, ... }:

{
  services.backups.apps.helium = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Helium";
    commandName = "helium-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.browsers;
    destinationSegments = [ "helium" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    # ** Helium keeps its data in the profile below, not in Application
    # ** Support, so nothing is taken from there.
    applicationSupportEntries = {
      applicationSupportPaths = [ ];
      excludePatterns = [ ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "net.imput.helium.plist";
          destinationPath = "net.imput.helium.plist";
        }
      ];

      excludePatterns = [ ];
    };

    configEntries = {
      configPaths = [
        {
          sourcePath = "browsers/helium-ven";
          destinationPath = "config/browsers/helium-ven";

          # Chromium rebuilds all of these on the next start.
          excludePatterns = [
            "Cache/"
            "Code Cache/"
            "GPUCache/"
            "GPUPersistentCache/"
            "GraphiteDawnCache/"
            "GrShaderCache/"
            "ShaderCache/"
            "DawnGraphiteCache/"
            "DawnWebGPUCache/"
            "Service Worker/CacheStorage/"
            "Service Worker/ScriptCache/"
            "component_crx_cache/"
            "extensions_crx_cache/"
            "blob_storage/"
            "Crashpad/"
            "Local Traces/"
            "BrowserMetrics*"
            "OptimizationGuide*/"
            "Safe Browsing*/"
            "Session Storage/"
            "Shared Dictionary/"
            "*.log"

            # Rewritten constantly while the browser runs.
            "Singleton*"
            "LOCK"
            "*-journal"
            "*-wal"
            "*-shm"
          ];
        }
        {
          sourcePath = "browsers/helium-extensions";
          destinationPath = "config/browsers/helium-extensions";
        }
      ];

      excludePatterns = [ ];
    };

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Helium";
        #   destinationPath = "additional/Somewhere/Helium";
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
    archivePrefix = "helium";

    /* iCloud */
    storeiCloud = false;
    cleanOldestiCloud = true;iCloudBackupsToKeep = 3;

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
