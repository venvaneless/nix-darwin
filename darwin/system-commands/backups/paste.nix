# darwin/system-commands/backups/paste.nix
# Paste backup command: `paste-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  pasteBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Paste";
    appSlug = "paste";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/com.wiheads.paste-direct"; destination = "com.wiheads.paste-direct"; }
      { path = "/Users/ven/Library/Preferences/com.wiheads.paste-direct.plist"; destination = "com.wiheads.paste-direct.plist"; }
    ];
  };
in
pasteBackup
