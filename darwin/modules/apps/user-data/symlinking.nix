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
  	./abetterfinderattributes-symlinks.nix
   	# ./abetterfinderrename-symlinks.nix
    # ./chromium-symlinks.nix
    # ./espanso-symlinks.nix
    # ./iterm-symlinks.nix
    ./paste-symlinks.nix
    # ./yate-symlinks.nix
    # ./vlc-symlinks.nix
    # ./zed-symlinks.nix
  ];
}
