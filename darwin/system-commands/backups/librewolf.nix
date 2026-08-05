# darwin/system-commands/backups/librewolf.nix
# LibreWolf browser backup command: `librewolf-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  librewolfBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "LibreWolf";
    appSlug = "librewolf";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    destinationSegments = [ "browsers" "librewolf" ];
    sources = [
      { path = "/Users/ven/Library/Application Support/librewolf"; destination = "librewolf"; }
      { path = "/Users/ven/Library/Preferences/net.librewolf.librewolf.plist"; destination = "app-pref/net.librewolf.librewolf.plist"; }
      { path = "/Users/ven/Library/Preferences/org.mozilla.librewolf.plist"; destination = "app-pref/org.mozilla.librewolf.plist"; }
    ];
  };
in
librewolfBackup
