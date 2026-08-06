# darwin/system-commands/backups/default.nix
#
# =====================================================================
# APPLICATION AND CONTAINER BACKUPS
#
# Container backups are manual by default. Set an individual `automatic`
# toggle only when that container should receive a scheduled LaunchAgent.
# =====================================================================

{ lib, pkgs, ... }:

let
  appBackupHelper = import ./app-backup-helper.nix { inherit lib pkgs; };
  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
{
  imports = [
    appBackupHelper.settingsModule
    containerBackupHelper.settingsModule

    ./archivebox.nix
    ./better-finder-attributes.nix
    ./better-finder-renamer.nix
    ./browsertrix.nix
    ./chrome-canary.nix
    ./dash.nix
    ./espanso.nix
    ./helium.nix
    ./iterm.nix
    ./karakeep.nix
    ./librewolf.nix
    ./mkcert.nix
    ./obsidian.nix
    ./obsidian-library.nix
    ./other-preferences.nix
    ./paste.nix
    ./pearcleaner.nix
    ./raycast.nix
    ./snippetslab.nix
    ./vaultwarden.nix
    ./vesktop.nix
    ./vlc.nix
    ./wallabag.nix
    ./wezterm.nix
    ./yate.nix
    ./zed.nix
  ];

  config = {
    # ---- GLOBAL APPLICATION BACKUP CONTROLS
    # Automatic application backups require this master switch and the
    # matching individual app module's automatic = true setting.
    services.appBackups = {
      paths = {
        homeDirectory = "/Users/ven";
        configDirectory = "/Users/ven/.config";
        applicationSupportDirectory = "/Users/ven/Library/Application Support";
        preferencesDirectory = "/Users/ven/Library/Preferences";
        externalBackupVolume = "/Volumes/SystemBackup";
        downloadsDirectory = "/Users/ven/Downloads";
        dataBackupsDirectory = "/Volumes/SystemBackup/data-backups";
        appBackupsDirectory = "/Volumes/SystemBackup/data-backups/app-backups";
        browserBackupsDirectory = "/Volumes/SystemBackup/data-backups/app-backups/browsers";
        terminalBackupsDirectory = "/Volumes/SystemBackup/system/terminal";
      };
      enabled = true;
      automaticEnabled = false;
      defaultAutomaticIntervalSeconds = 86400;
      defaultMinimumIntervalSeconds = 28800;
      defaultCpuLimitPercent = 25;
      defaultExtraExcludePatterns = [
        "sockets/"
        "private/socket"
        "*.sock"
      ];
    };

    # ---- GLOBAL CONTAINER BACKUP CONTROLS
    # Automatic container backups require this master switch and the matching
    # individual container module's automatic = true setting.
    services.containerBackups = {
      paths = {
        homeDirectory = "/Users/ven";
        configDirectory = "/Users/ven/.config";
        containerDirectory = "/Users/ven/.config/containers";
        externalBackupVolume = "/Volumes/SystemBackup";
        downloadsDirectory = "/Users/ven/Downloads";
        dataBackupsDirectory = "/Volumes/SystemBackup/data-backups";
        containerBackupsDirectory = "/Volumes/SystemBackup/data-backups/container-backups";
      };
      enabled = true;
      automaticEnabled = false;
      defaultAutomaticIntervalSeconds = 86400;
      defaultMinimumIntervalSeconds = 28800;
      defaultCpuLimitPercent = 35;
      defaultExtraExcludePatterns = [
        "sockets/"
        "private/socket"
        "*.sock"
      ];
      runOnRebuild = false;

    # ---- ENABLED MANUAL COMMANDS
    archivebox.enable = true;
    browsertrix.enable = true;
    karakeep.enable = true;
    vaultwarden.enable = true;
    wallabag.enable = true;

    };
  };
}
