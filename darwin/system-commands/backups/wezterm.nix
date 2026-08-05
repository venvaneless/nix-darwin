# darwin/system-commands/backups/wezterm.nix
# WezTerm backup command: `wezterm-backup`.

{ config, lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  weztermBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "WezTerm";
    appSlug = "wezterm";
    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    sources = [
      { path = "/Users/ven/Library/Application Support/wezterm"; destination = "wezterm"; }
      { path = "/Users/ven/.config/wezterm"; destination = "user-config/wezterm"; }
      { path = "/Users/ven/Library/Preferences/com.github.wez.wezterm.plist"; destination = "com.github.wez.wezterm.plist"; }
    ];
  };
in
weztermBackup
