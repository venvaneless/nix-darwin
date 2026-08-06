# darwin/system-commands/backups/snippetslab.nix
# SnippetsLab backup command: `snippetslab-backup`.

{ config, lib, pkgs, ... }:

let
  applicationSupportSources = [
    {
      sourcePath = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Markdown Themes";
      destinationPath = "assets/markdown-themes";
    }
    {
      sourcePath = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Themes";
      destinationPath = "assets/themes";
    }
  ];
  applicationPreferences = [
    {
      sourcePath = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Preferences/com.renfei.SnippetsLab.plist";
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
    inherit applicationSupportSources applicationPreferences additionalSources;
    inherit archive stageInDownloads archiveFilenameTemplate archiveTimestampFormat archivePrefix preserveSymlinks;
  };
in
snippetslabBackup
