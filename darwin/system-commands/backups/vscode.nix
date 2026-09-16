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

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "vscode" ];

    # ---- EDITABLE BACKUP CONTENTS
    # sourcePath resolves from the root above it; destinationPath is
    # where it lands inside the archive. Application Support goes under
    # app-support/, configuration under config/, and a lone preference
    # file sits at the archive root. Each entry may exclude its own
    # subpaths.
    #
    # ** The global user-data folder VS Code uses when it is not told to
    # ** use another one. This machine points it at the portable tree
    # ** below, so once the VS Code module's links exist only the link
    # ** itself is stored here.

    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          sourcePath = "Code";
          destinationPath = "app-support/Code";
        }
      ];

      # Electron rebuilds every one of these on the next start.
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
        "*.log"
      ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.microsoft.VSCode.plist";
          destinationPath = "com.microsoft.VSCode.plist";
        }
      ];

      excludePatterns = [ ];
    };

    # ** The portable tree this machine uses, entry by entry, so each part
    # ** can be restored on its own.

    configEntries = {
      configPaths = [
        {
          sourcePath = "vscode/user-data/User/settings.json";
          destinationPath = "config/user-settings.json";
        }
        {
          sourcePath = "vscode/user-data/User/keybindings.json";
          destinationPath = "config/user-keybindings.json";
        }
        {
          sourcePath = "vscode/user-data/User/chatLanguageModels.json";
          destinationPath = "config/user-chat-language-models.json";
        }
        {
          sourcePath = "vscode/argv.json";
          destinationPath = "config/argv.json";
        }
        {
          sourcePath = "vscode/user-data/User/profiles";
          destinationPath = "config/profile-settings";
        }
        {
          sourcePath = "vscode/user-data/User/snippets";
          destinationPath = "config/snippets";
        }
        {
          sourcePath = "vscode/user-data/User/globalStorage";
          destinationPath = "config/extension-data";
        }
        {
          sourcePath = "vscode/user-data/User/workspaceStorage";
          destinationPath = "config/workspace-data";
        }
        {
          sourcePath = "vscode/extensions";
          destinationPath = "config/extensions";
        }
        {
          sourcePath = "vscode/shared-data";
          destinationPath = "config/shared-data";
        }
        {
          sourcePath = "vscode/agent-plugins";
          destinationPath = "config/agent-plugins";
        }
        {
          sourcePath = "vscode/user-data/User/History";
          destinationPath = "config/local-history";
        }
      ];

      excludePatterns = [ ];
    };

    # ** Workspace settings live in each project's own .vscode/settings.json,
    # ** not in VS Code's directories. List the projects here to include them.

    # Absolute paths outside the roots above. Uncomment to add one.

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
    showProgress = true;
  };
}
