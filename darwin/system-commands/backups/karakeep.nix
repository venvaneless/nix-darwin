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

import ./mk-container-backup.nix {
  inherit config lib pkgs;

  appName = "Karakeep";
  appSlug = "karakeep";
  sourceDir = config.services.karakeep.dataDir;
  scheduledHour = 6;
  scheduledMinute = 0;
}
