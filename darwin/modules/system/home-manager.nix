# /Users/ven/dotfiles/nix/darwin/modules/system/home-manager.nix
#
# DARWIN: HOME MANAGER (INTEGRATED)
# ================================================
# This module enables Home Manager as part of nix-darwin.
# It applies your user config whenever you run:
#   drs / drb / drn  → darwin-rebuild
#
# Contains:
#   - user settings for "ven"
#   - imports of user-level modules (Zsh, symlinks, etc.)
#
# Does NOT contain:
#   - systemPath (belongs to nix-darwin system-level)
#   - systemPackages (belongs to system-level)
# ================================================

{ pkgs, lib, ... }:

{
  # --- Main User ---
  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;

    users.ven = {
      home.username      = "ven";
      home.homeDirectory = "/Users/ven";
      home.stateVersion  = "25.11";

      # --- User modules ---
      imports = [
        ../terminal/zsh.nix
        ../apps/user-data/symlinking.nix
      ];
    };
  };
}
