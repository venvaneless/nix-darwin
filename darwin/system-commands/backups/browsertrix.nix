# darwin/system-commands/backups/browsertrix.nix
#
# Backs up Browsertrix container data to SystemBackup.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  containerBackupHelper = import ./container-backup-helper.nix { inherit lib pkgs; };
in
containerBackupHelper.mkContainerBackup {
  inherit config;

  appName = "Browsertrix";
  appSlug = "browsertrix";
  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;
  sourceDir = "/Users/ven/.config/containers/browsertrix";
  scheduledHour = 2;
  scheduledMinute = 0;
}
