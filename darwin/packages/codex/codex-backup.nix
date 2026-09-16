# darwin/packages/codex/codex-backup.nix
# Codex backup command: `codex-backup`.

{ paths, ... }:

{
  services.backups.apps.codex = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Codex";

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.containers;
    destinationSegments = [ "codex" ];

    # ---- EDITABLE BACKUP CONTENTS
    # ** Each part lands at the same relative path in the archive root, so
    # ** extracting the archive into ~/.config/codex restores it.

    configEntries = {
      configPaths = [
        {
          sourcePath = "codex/chatgpt";
          destinationPath = "chatgpt";
        }
        {
          sourcePath = "codex/api";
          destinationPath = "api";
        }
        {
          sourcePath = "codex/shared";
          destinationPath = "shared";
        }
        {
          sourcePath = "codex/backups";
          destinationPath = "backups";
        }
      ];

      excludePatterns = [
        "*.sock"
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
    archivePrefix = "codex";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = true;
    automaticIntervalSeconds = 28800;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 10;

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
  };
}
