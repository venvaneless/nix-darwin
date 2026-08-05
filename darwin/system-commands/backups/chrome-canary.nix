# darwin/system-commands/backups/chrome-canary.nix
# Chrome Canary browser backup command: `chrome-canary-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  chromeCanaryBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Chrome Canary";
    appSlug = "chrome-canary";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    destinationSegments = [ "browsers" "chrome-canary" ];
    sources = [
      { path = "/Users/ven/Library/Application Support/Google/Chrome Canary"; destination = "Chrome Canary"; }
      { path = "/Users/ven/Library/Preferences/com.google.Chrome.canary.plist"; destination = "com.google.Chrome.canary.plist"; }
    ];
  };
in
chromeCanaryBackup
