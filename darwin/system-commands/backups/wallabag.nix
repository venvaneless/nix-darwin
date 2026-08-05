# darwin/system-commands/backups/wallabag.nix
#
# Backs up Wallabag container data to SystemBackup.

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

  appName = "Wallabag";
  appSlug = "wallabag";
  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 35;
  runOnRebuild = false;
  sourceDir = "/Users/ven/.config/containers/wallabag";
  scheduledHour = 5;
  scheduledMinute = 0;
}
