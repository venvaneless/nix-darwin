# darwin/system-commands/backups/espanso.nix
# Espanso backup command: `espanso-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  espansoBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Espanso";
    appSlug = "espanso";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/.config/espanso"; destination = "user-config/espanso"; }
      { path = "/Users/ven/Library/Preferences/com.federicoterzi.espanso.plist"; destination = "com.federicoterzi.espanso.plist"; }
    ];
  };
in
espansoBackup
