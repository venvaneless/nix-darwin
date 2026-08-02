# darwin/system-commands/backups/browsertrix.nix
#
# Backs up Browsertrix container data to iCloud Drive.

{
  config,
  lib,
  pkgs,
  ...
}:

import ./mk-container-backup.nix {
  inherit config lib pkgs;

  appName = "Browsertrix";
  appSlug = "browsertrix";
  sourceDir = "/Users/ven/.config/containers/browsertrix";
}
