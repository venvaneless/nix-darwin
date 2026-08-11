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
        ../shared/terminal
        ../shared/terminal/nvim
        ../shared/terminal/cli-tuis
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
