# darwin/system-commands/backups/wallabag.nix
#
# Backs up Wallabag container data to SystemBackup.

{
  config,
  lib,
  pkgs,
  ...
}:

import ./container-backup-helper.nix {
  inherit config lib pkgs;

  appName = "Wallabag";
  appSlug = "wallabag";
  sourceDir = "/Users/ven/.config/containers/wallabag";
  scheduledHour = 5;
  scheduledMinute = 0;
}
