# darwin/system-commands/default.nix
#
# =====================================================================
# SYSTEM COMMANDS
#
# Imports custom command-line applications installed system-wide, and
# assigns this machine's backup values. The backup option shape and its
# defaults live in options/backups; this file only sets values.
# =====================================================================

{ paths, ... }:

let
  # ---- SHARED PATHS ---- #
  # Source roots and the external backup volume layout come from the
  # centralized path definitions.
  userPaths = paths.darwin.home;
  libraryPaths = paths.darwin.library;
  backupPaths = paths.darwin.backups;
in
{
  imports = [
    ./backups
    ./fmove.nix
    ./ftar.nix
    ./generations-cleanup.nix
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
    # These are the machine-wide defaults for every container backup. Each
    # container overrides any of them with the same knob in its own file,
    # so a container may be enabled or run automatically while the global
    # default is off, and vice versa. The per-container enable, automatic,
    # and runOnRebuild flags live in each container file, not here.
    services.backups = {
      paths = {
        homeDirectory = userPaths.root;
        configDirectory = userPaths.config;
        containerDirectory = userPaths.containers;
        externalBackupVolume = backupPaths.volume;
        dataBackupsDirectory = backupPaths.data;
        containerBackupsDirectory = backupPaths.containers;
        downloadsDirectory = userPaths.downloads;
        stagingDirectory = backupPaths.staging;
      };
      enabled = true;
      automaticEnabled = false;
      runOnRebuild = false;
      defaultAutomaticIntervalSeconds = 86400;
      defaultMinimumIntervalSeconds = 28800;
      defaultCpuLimitPercent = 35;
      minimumCpuLimitPercent = 5;
      maximumCpuLimitPercent = 50;
      defaultTransferLimitKiBps = 4096;
      defaultShowProgress = true;
      defaultExtraExcludePatterns = [
        "sockets/"
        "private/socket"
        "*.sock"
      ];
    };
  };
}
