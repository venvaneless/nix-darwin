# darwin/system-commands/backups/karakeep.nix
#
# =====================================================================
# KARAKEEP CONTAINER BACKUP
#
# Creates a daily, low-priority backup only when Karakeep data changed.
# The archive is built and verified locally before moving to SystemBackup.
# =====================================================================

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

  appName = "Karakeep";
  appSlug = "karakeep";
  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;
  sourceDir = config.services.karakeep.dataDir;
  scheduledHour = 6;
  scheduledMinute = 0;
}
