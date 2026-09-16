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

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "vscode" ];

    # ---- EDITABLE BACKUP CONTENTS
    # ** Everything VS Code uses lives in ~/.config/vscode. Each part lands
    # ** at the same relative path in the archive root, so extracting the
    # ** archive into ~/.config/vscode restores it.

    configEntries = {
      configPaths = [
        {
          sourcePath = "vscode/argv.json";
          destinationPath = "argv.json";
        }
        {
          sourcePath = "vscode/user-data/User";
          destinationPath = "user-data/User";
        }
        {
          sourcePath = "vscode/extensions";
          destinationPath = "extensions";
        }
        {
          sourcePath = "vscode/agent-plugins";
          destinationPath = "agent-plugins";
        }
        {
          sourcePath = "vscode/shared-data";
          destinationPath = "shared-data";
        }
        {
          sourcePath = "vscode/backup-configs";
          destinationPath = "backup-configs";
        }
      ];

      excludePatterns = [
        "*.log"
      ];
    };

    # ** Workspace settings live in each project's own .vscode/settings.json.
    # ** List the projects here to include them.

    # Absolute paths outside the roots above. Uncomment to add one.

    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Developer/example/.vscode";
        #   destinationPath = "workspace-settings/example";
        # }
      ];

      excludePatterns = [ ];
    };

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "vscode";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;

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
