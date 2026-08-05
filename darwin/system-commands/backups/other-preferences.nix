# darwin/system-commands/backups/other-preferences.nix
# Other preferences backup command: `other-preferences-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  otherPreferencesBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Other Preferences";
    appSlug = "other-preferences";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    commandName = "other-preferences-backup";
    sources = [
      { path = "/Users/ven/Library/Preferences/com.stonerl.Thaw.plist"; destination = "app-pref/com.stonerl.Thaw.plist"; }
      { path = "/Users/ven/Library/Preferences/com.apple.Terminal.plist"; destination = "app-pref/com.apple.Terminal.plist"; }
    ];
  };
in
otherPreferencesBackup
