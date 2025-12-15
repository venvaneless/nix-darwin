# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/system-options.nix
#
# SYSTEM OPTIONS (GLUE)
# ============================================================
# Aggregates core macOS system UI modules:
# - Dock options
# - Finder options
# - Fonts
# - Trackpad options
#
# This file is imported once from base.nix and in turn imports
# the individual system modules to keep base.nix clean.
# ============================================================
#
{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # MODULE IMPORTS
  # System-level UI / UX configuration
  # ------------------------------------------------------------
  imports = [
    ./dock-options.nix
    ./finder-options.nix
    ./fonts.nix
    ./statusbar.nix
    ./trackpad.nix
  ];
}
