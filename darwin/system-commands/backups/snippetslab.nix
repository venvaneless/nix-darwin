# darwin/system-commands/backups/snippetslab.nix
# SnippetsLab backup command: `snippetslab-backup`.

{ config, lib, pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # macOS Library roots come from the centralized path definitions.
  #
  # ** SnippetsLab is sandboxed, so its data lives inside an Apple-managed
  # ** app container. These entries are read-only backup sources; nothing
  # ** here writes into the container.
  paths = import ../../../options/paths.nix { };

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
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "snippetslab";
  preserveSymlinks = true;

  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  snippetslabBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "SnippetsLab";
    appSlug = "snippetslab";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    showProgress = true;
    inherit applicationSupportSources applicationPreferences additionalSources;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
snippetslabBackup
