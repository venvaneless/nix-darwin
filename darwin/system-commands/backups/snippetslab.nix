# darwin/system-commands/backups/snippetslab.nix
# SnippetsLab backup command: `snippetslab-backup`.

{ appBackupHelper, config, paths, ... }:

let
  # ---- SHARED PATHS ---- #
  # macOS Library roots come from the centralized path definitions.
  #
  # ** SnippetsLab is sandboxed, so its data lives inside an Apple-managed
  # ** app container. These entries are read-only backup sources; nothing
  # ** here writes into the container.
  # Sandbox container root for SnippetsLab
  containerData = "${paths.darwin.library.containers}/com.renfei.SnippetsLab/Data/Library";

  applicationSupportSources = [
    {
      sourcePath = "${containerData}/Application Support/Markdown Themes";
      destinationPath = "assets/markdown-themes";
    }
    {
      sourcePath = "${containerData}/Application Support/Themes";
      destinationPath = "assets/themes";
    }
  ];
  applicationPreferences = [
    {
      sourcePath = "${containerData}/Preferences/com.renfei.SnippetsLab.plist";
      destinationPath = "com.renfei.SnippetsLab.plist";
    }
  ];
  additionalSources = [ ];

  # ---- EDITABLE EXCLUSIONS
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  showProgress = true;

  # ---- INDIVIDUAL ARCHIVE CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "snippetslab";
  preserveSymlinks = true;

  snippetslabBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "SnippetsLab";
    appSlug = "snippetslab";
    inherit automatic automaticIntervalSeconds minimumIntervalSeconds cpuLimitPercent showProgress;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
    inherit applicationSupportSources applicationPreferences additionalSources extraExcludePatterns;
  };
in
snippetslabBackup
