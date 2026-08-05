# darwin/system-commands/backups/iterm.nix
# iTerm2 backup command: `iterm-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  itermBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "iTerm2";
    appSlug = "iterm";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    destinationRoot = "terminalBackups";
    destinationSegments = [ "iterm" "backups" ];
    extraExcludePatterns = [
      "sockets/"
      "private/socket"
      "*.sock"
    ];
    sources = [
      { path = "/Users/ven/Library/Application Support/iTerm2"; destination = "iTerm2"; }
      { path = "/Users/ven/Library/Preferences/com.googlecode.iterm2.plist"; destination = "com.googlecode.iterm2.plist"; }
    ];
  };
in
itermBackup
