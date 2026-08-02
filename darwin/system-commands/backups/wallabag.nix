# darwin/system-commands/backups/wallabag.nix
#
# Backs up Wallabag container data to iCloud Drive.

{
  config,
  lib,
  pkgs,
  ...
}:

import ./mk-container-backup.nix {
  inherit config lib pkgs;

  appName = "Wallabag";
  appSlug = "wallabag";
  sourceDir = "/Users/ven/.config/containers/wallabag";
}
