# darwin/system-commands/backups/browsertrix.nix
#
# Backs up Browsertrix container data to SystemBackup.

{
  config,
  lib,
  pkgs,
  ...
}:

import ./container-backup-helper.nix {
  inherit config lib pkgs;

  appName = "Browsertrix";
  appSlug = "browsertrix";
  sourceDir = "/Users/ven/.config/containers/browsertrix";
  scheduledHour = 2;
  scheduledMinute = 0;
}
