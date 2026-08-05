# darwin/system-commands/backups/vlc.nix
# VLC backup command: `vlc-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  vlcBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "VLC";
    appSlug = "vlc";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/org.videolan.vlc"; destination = "org.videolan.vlc"; }
      { path = "/Users/ven/Library/Preferences/org.videolan.vlc"; destination = "app-pref/org.videolan.vlc"; }
      { path = "/Users/ven/Library/Preferences/org.videolan.vlc.plist"; destination = "app-pref/org.videolan.vlc.plist"; }
    ];
  };
in
vlcBackup
