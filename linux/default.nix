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
    # ---- SHARED SERVICE OPTIONS ---- #
    # Services remain disabled until this host enables them explicitly.
    ../options/services/default.nix

    # ---- SHARED TERMINAL CONFIGURATION ---- #
    inputs.self.homeModules.sharedTerminal

    # ---- SHARED PACKAGE DECLARATIONS ---- #
    # Every category lives in one file; each entry keeps its own
    # enable flag and per-platform installOn toggle.
    ../shared/packages.nix

    # ---- SHARED SYSTEM COMMANDS ---- #
    # The portable Obsidian archive checker is user-scoped while this host
    # remains on standalone Home Manager.
    (import ../shared/system-commands/obsidian-archive-check.nix {
      installTarget = "home";
    })
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
