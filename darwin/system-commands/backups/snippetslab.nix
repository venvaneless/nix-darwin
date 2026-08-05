# darwin/system-commands/backups/snippetslab.nix
# SnippetsLab backup command: `snippetslab-backup`.

{ config, lib, pkgs, ... }:

let
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
    sources = [
      { path = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Markdown Themes"; destination = "app-support/Markdown Themes"; }
      { path = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Themes"; destination = "app-support/Themes"; }
      { path = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Preferences/com.renfei.SnippetsLab.plist"; destination = "com.renfei.SnippetsLab.plist"; }
    ];
  };
in
snippetslabBackup
