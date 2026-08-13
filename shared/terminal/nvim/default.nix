# shared/terminal/nvim/default.nix

# =====================================================================
# NEOVIM: MAIN MODULE
#
# Shared AstroNvim configuration for macOS and Linux
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ven.features.terminal.nvim;
in
{
  options.ven.features.terminal.nvim = {
    enable = lib.mkEnableOption "Neovim and AstroNvim configuration";

    neovide.enable = lib.mkEnableOption "Neovide graphical Neovim client";
  };

  imports = [
    
    # Keeps the inherited AstroNvim starter files under Home Manager ownership.
    ./starter-plugin-specs.nix

    # ---- CORE CONFIGURATION ---- #
    ./core.nix
    ./keyboard.nix

    # ---- VIEW AND NAVIGATION ---- #
    # View and Search
    ./explorer.nix
    ./telescope.nix

    # Project switching backed by snacks and resession sessions
    ./projects.nix

    # ---- VERSION CONTROL ---- #
    ./git.nix

    # ---- UI ---- #
    ./theme.nix
    ./icons.nix

    # Snacks notifier styling
    ./notify.nix

    # ---- ADDITIONAL COMPONENTS ---- #
    # Additional UI components
    ./dropbar.nix
    ./heirline.nix
    
    # ---- COMPLETIONS / LSP / LINTING ---- #
    ./completion.nix
    ./lint.nix
    ./lsp.nix
  ];

  config = lib.mkIf cfg.enable {
    # ---- NEOVIM PACKAGE ---- #
    # Installs the standard Nix Neovim package and its common command aliases.
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # ---- LEGACY REMOTE PROVIDERS ---- #
      # Keeps the established Python and Ruby remote-plugin providers available.
      # These settings preserve the Home Manager behavior from state version 25.11.
      withPython3 = true;
      withRuby = true;
    };

    # ---- NEOVIDE PACKAGE ---- #
    # Uses the same XDG Neovim configuration without a separate HOME wrapper.
    home.packages = lib.optionals cfg.neovide.enable [
      pkgs.neovide
    ];
  };
}
