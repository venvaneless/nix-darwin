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
            "Singleton*"
            "*.log"
          ];
        }
        {
          sourcePath = "browsers/helium-extensions";
          destinationPath = "config/browsers/helium-extensions";
        }
      ];

      excludePatterns = [ ];
    };

    # Absolute paths outside the roots above. Uncomment to add one.

    # Absolute paths outside the roots above. Uncomment to add one.

    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Helium";
        #   destinationPath = "additional/Somewhere/Helium";
        # }
      ];

      excludePatterns = [ ];
    };

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "helium";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
  };
}
