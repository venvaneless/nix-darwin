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
  # ---- SHARED PATHS ---- #
  # Source roots and the external backup volume layout come from the
  # centralized path definitions.
  paths = import ../../../options/paths.nix { };

  userPaths = paths.darwin.home;
  libraryPaths = paths.darwin.library;
  backupPaths = paths.darwin.backups;

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
        homeDirectory = userPaths.root;
        configDirectory = userPaths.config;
        applicationSupportDirectory = libraryPaths.applicationSupport;
        preferencesDirectory = libraryPaths.preferences;
        externalBackupVolume = backupPaths.volume;
        stagingDirectory = backupPaths.staging;
        dataBackupsDirectory = backupPaths.data;
        appBackupsDirectory = backupPaths.apps;
        browserBackupsDirectory = backupPaths.browsers;
        terminalBackupsDirectory = backupPaths.terminal;
      };
      enabled = true;
      automaticEnabled = false;
      defaultAutomaticIntervalSeconds = 86400;
      defaultMinimumIntervalSeconds = 28800;
      defaultCpuLimitPercent = 25;
      maximumCpuLimitPercent = 10;
      defaultTransferLimitKiBps = 4096;
      defaultShowProgress = true;
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
        homeDirectory = userPaths.root;
        configDirectory = userPaths.config;
        containerDirectory = userPaths.containers;
        externalBackupVolume = backupPaths.volume;
        downloadsDirectory = userPaths.downloads;
        stagingDirectory = backupPaths.staging;
        dataBackupsDirectory = backupPaths.data;
        containerBackupsDirectory = backupPaths.containers;
      };
      enabled = true;
      automaticEnabled = false;
      defaultAutomaticIntervalSeconds = 86400;
      defaultMinimumIntervalSeconds = 28800;
      defaultCpuLimitPercent = 35;
      maximumCpuLimitPercent = 10;
      defaultTransferLimitKiBps = 4096;
      defaultShowProgress = true;
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
