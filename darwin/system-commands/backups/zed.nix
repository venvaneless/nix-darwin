# darwin/system-commands/backups/zed.nix
# Zed backup command: `zed-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  zedBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Zed";
    appSlug = "zed";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/zed"; destination = "zed"; }
      { path = "/Users/ven/.config/zed"; destination = "user-config/zed"; }
      { path = "/Users/ven/Library/Preferences/dev.zed.Zed.plist"; destination = "dev.zed.Zed.plist"; }
    ];
  };
in
zedBackup
