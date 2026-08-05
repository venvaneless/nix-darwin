# darwin/system-commands/backups/better-finder-attributes.nix
# A Better Finder Attributes backup command: `better-attributes-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  betterAttributesBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "A Better Finder Attributes";
    appSlug = "better-finder-attributes";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    commandName = "better-attributes-backup";
    sources = [
      { path = "/Users/ven/Library/Application Support/A Better Finder Attributes 7"; destination = "A Better Finder Attributes 7"; }
      { path = "/Users/ven/Library/Preferences/net.publicspace.abfa7.plist"; destination = "net.publicspace.abfa7.plist"; }
    ];
  };
in
betterAttributesBackup
