# /Users/ven/dotfiles/nix/darwin/modules/apps/user-data/symlinking.nix
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
  	./iterm-symlinks.nix
    ./zed-symlinks.nix

    # Future app user-data modules:
    # ./vscode-symlinks.nix
    # ./obsidian-symlinks.nix
    # ./wezterm-symlinks.nix
  ];
}
