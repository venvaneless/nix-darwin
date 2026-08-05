# darwin/system-commands/backups/raycast.nix
# Raycast backup command: `raycast-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  raycastBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Raycast";
    appSlug = "raycast";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    requiredAny = [ [
      "/Users/ven/Library/Application Support/com.raycast.macos"
      "/Users/ven/Library/Application Support/com.raycast-x.macos"
    ] ];
    sources = [
      { path = "/Users/ven/Library/Application Support/com.raycast.macos"; destination = "app-support/com.raycast.macos"; }
      { path = "/Users/ven/Library/Application Support/com.raycast-x.macos"; destination = "app-support/com.raycast-x.macos"; }
      { path = "/Users/ven/Library/Application Support/com.raycast.shared"; destination = "app-support/com.raycast.shared"; }
      { path = "/Users/ven/Library/Preferences/com.raycast.macos.plist"; destination = "com.raycast.macos.plist"; }
      { path = "/Users/ven/.config/raycast"; destination = "user-config/raycast"; }
    ];
  };
in
raycastBackup
