# /Users/ven/dotfiles/nix/darwin/modules/system/home-manager-standalone.nix
#
# DARWIN: HOME MANAGER (STANDALONE)
# ================================================
# This file is used when you manually run:
#   drh  → home-manager switch --flake ...#ven
#
# It has the same user config as the integrated version
# but WITHOUT any nix-darwin system-level options.
#
# Contains:
#   - direct HM 'home.*' configuration
#   - user-level imports (Zsh, symlinks, etc.)
#
# Must NOT contain:
#   - environment.systemPath
#   - environment.systemPackages
#   - nix-darwin-specific options
# ================================================

{ pkgs, lib, ... }:

{
	# --- Main User ---
  home = {
    username      = "ven";
    homeDirectory = "/Users/ven";
    stateVersion  = "25.11";
  };

  # --- User modules ---
  imports = [
    ../terminal/zsh.nix
    ../apps/user-data/symlinking.nix
  ];
}
