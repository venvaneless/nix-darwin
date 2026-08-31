# nixos/home-manager.nix
#
# =====================================================================
# NIXOS: HOME MANAGER (INTEGRATED)
#
# Configures the supplied NixOS user through the shared terminal module.
# System ownership remains in nixos/default.nix.
# =====================================================================

{ ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ven = {
      # ---- HOME MANAGER IDENTITY ---- #
      home = {
        username = "ven";
        homeDirectory = "/home/ven";
        stateVersion = "26.05";
      };

      # ---- SHARED TERMINAL CONFIGURATION ---- #
      imports = [
        # ---- SHARED SERVICE OPTIONS ---- #
        # Services remain disabled until this host enables them explicitly.
        ../options/services/default.nix

        ../shared/terminal
        ../shared/terminal/nvim
        ../shared/terminal/cli-tuis

        # ---- SHARED PACKAGE DECLARATIONS ---- #
        # User-scoped packages and session variables belong to Home Manager.
        # Every category lives in one file; each entry keeps its own
        # enable flag and per-platform installOn toggle.
        ../shared/packages.nix
      ];

      # ---- HOST TERMINAL FEATURES ---- #
      # CLI/TUI defaults come from shared/terminal/cli-tuis/default.nix.
      # This host may override individual tools under cliTuis.<tool>.enable.
      ven.features.terminal.nvim = {
        enable = true;
        neovide.enable = false;
      };

      # ---- NIX ALIAS HOST ---- #
      ven.features.terminal.fish.nixProfile.flakeHost = "ven";
    };
  };
}
