# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/symlinking.nix
#
# APP USER-DATA SYMLINK LOADER
# ============================================================
# This module aggregates all per-app “user-data” migration
# and symlinking modules.
#
# Each app gets its own file. This file simply wires
# them together so Home Manager only has to import THIS file once.
# ============================================================

{ ... }:

{
  imports = [
    # ./chromium-symlinks.nix
    # ./iterm-symlinks.nix
    ./zed-symlinks.nix
  ];
}
