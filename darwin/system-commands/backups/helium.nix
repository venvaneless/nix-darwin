# darwin/system-commands/backups/helium.nix
# Helium browser backup command: `helium-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  heliumBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Helium";
    appSlug = "helium";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    destinationSegments = [ "browsers" "helium" ];
    sources = [
      { path = "/Users/ven/Library/Application Support/net.imput.helium"; destination = "net.imput.helium"; }
      { path = "/Users/ven/Library/Preferences/net.imput.helium.plist"; destination = "net.imput.helium.plist"; }
    ];
  };
in
heliumBackup
