# darwin/system-commands/backups/vscode.nix
# Visual Studio Code backup command: `vscode-backup`.
#
# Values only. Every knob below is declared in
# options/backups/app-backup-helper.nix, which owns what each one means
# and how the backup is carried out.

{ paths, ... }:

{
  services.backups.apps.vscode = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Visual Studio Code";
    commandName = "vscode-backup";

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "vscode" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    # ** Everything VS Code uses lives in ~/.config/vscode. Each part lands
    # ** at the same relative path in the archive root, so extracting the
    # ** archive into ~/.config/vscode restores it.
    configEntries = {
      configPaths = [
        {
          sourcePath = "vscode/cli";
          destinationPath = "cli";
        }
        {
          sourcePath = "vscode/extensions";
          destinationPath = "extensions";
        }
        {
          sourcePath = "vscode/shared-data";
          destinationPath = "shared-data";
        }
        {
          sourcePath = "vscode/user-data";
          destinationPath = "user-data";

          # Electron rebuilds these on the next start.
          excludePatterns = [
            "Cache/"
            "CachedData/"
            "CachedConfigurations/"
            "CachedExtensionVSIXs/"
            "CachedProfilesData/"
            "Code Cache/"
            "GPUCache/"
            "DawnGraphiteCache/"
            "DawnWebGPUCache/"
            "Service Worker/"
            "Session Storage/"
            "Shared Dictionary/"
            "blob_storage/"
            "Crashpad/"
            "logs/"

            # Rewritten constantly while the app runs.
            "*.sock"
            "code.lock"
            "*-journal"
            "*-wal"
          ];
        }
        {
          sourcePath = "vscode/agent-plugins";
          destinationPath = "agent-plugins";
        }
        {
          sourcePath = "vscode/argv.json";
          destinationPath = "argv.json";
        }
      ];

      excludePatterns = [
        "*.log"
      ];
    };

    # Absolute paths for data outside the roots above. Uncomment to add one.
    # ** Workspace settings live in each project's own .vscode/settings.json.
    # ** List the projects here to include them.
    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Developer/example/.vscode";
        #   destinationPath = "workspace-settings/example";
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
    archivePrefix = "vscode";

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
