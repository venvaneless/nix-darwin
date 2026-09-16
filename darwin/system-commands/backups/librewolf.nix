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

      # Firefox rebuilds all of these on the next start.
      excludePatterns = [
        "cache2/"
        "startupCache/"
        "shader-cache/"
        "thumbnails/"
        "crashes/"
        "minidumps/"
        "datareporting/"
        "saved-telemetry-pings/"
        "*.log"
      ];
    };

    # Absolute paths outside the roots above. Uncomment to add one.

    # Absolute paths outside the roots above. Uncomment to add one.

    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/LibreWolf";
        #   destinationPath = "additional/Somewhere/LibreWolf";
        # }
      ];

      excludePatterns = [ ];
    };

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "librewolf";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
  };
}
