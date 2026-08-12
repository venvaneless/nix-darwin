# linux/default.nix
#
# =====================================================================
# LINUX: STANDALONE HOME MANAGER
#
# User configuration for the regular Linux ROG Zephyrus host. System
# configuration remains outside this repository's standalone HM output.
# =====================================================================

{ inputs, ... }:

{
  imports = [
    # ---- SHARED TERMINAL CONFIGURATION ---- #
    inputs.self.homeModules.sharedTerminal

    # ---- SHARED PACKAGE CATEGORIES ---- #
    ../shared/packages/apps-pkgs.nix
    ../shared/packages/media-pkgs.nix
    ../shared/packages/development-pkgs.nix
    ../shared/packages/productivity-pkgs.nix
    ../shared/packages/tools-pkgs.nix
  ];

  # ---- HOME MANAGER IDENTITY ---- #
  home = {
    username = "ven";
    homeDirectory = "/home/ven";
    stateVersion = "26.05";
  };

  # ---- HOST TERMINAL FEATURES ---- #
  # CLI/TUI defaults come from shared/terminal/cli-tuis/default.nix.
  # This host may override individual tools under cliTuis.<tool>.enable.
  ven.features.terminal.nvim = {
    enable = true;
    neovide.enable = false;
  };

  # ---- NIX ALIAS HOST ---- #
  ven.features.terminal.fish.nixProfile.flakeHost = "ven";
}
