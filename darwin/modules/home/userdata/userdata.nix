# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/userdata/userdata.nix
#
# APP USER-DATA BACKUP LOADER
# ============================================================
# This module aggregates all per-app “user-data” BACKUP modules.
#
# These modules DO NOT symlink. They only back up runtime data
# into your repo folders.
#
# Each app gets its own file. This file simply wires them
# together so Home Manager only has to import THIS file once.
# ============================================================

{ ... }:

{
  imports = [
    ./raycast-userdata.nix
    ./paste-userdata.nix
    ./yate-userdata.nix
  ];
}
