# shared/terminal/cli-tuis/eza/eza.nix
#
# =====================================================================
# EZA
#
# Modern, maintained replacement for ls
#
# Installation and settings are managed through Home Manager.
# Each theme lives in its own eza-<name>.nix file with its own toggle,
# imported at the bottom of this file. Only one may be enabled.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.eza;

  # ---- ACTIVE THEMES ---- #
  # eza reads a single theme.yml, so the toggles are mutually exclusive.
  enabledThemes = lib.attrNames (lib.filterAttrs (_: theme: theme.enable) cfg.themes);
in
{
  options.ven.features.terminal.cliTuis.eza.enable = lib.mkEnableOption "Eza file listing";

  config = lib.mkIf cfg.enable {
    # ---- CONFLICTING THEMES ---- #
    assertions = [
      {
        assertion = lib.length enabledThemes <= 1;
        message = ''
          eza: only one theme may be enabled at a time, but these are on:
          ${lib.concatStringsSep ", " enabledThemes}

          Disable the others under
          ven.features.terminal.cliTuis.eza.themes.<name>.enable.
        '';
      }
    ];

    programs.eza = {
      # Install and enable eza
      enable = true;

      # ---- SHELL INTEGRATION ---- #
      # Provides the ls/ll/la/lt/lla aliases. Fish is the only configured
      # shell here; the rest stay off so no stray aliases are generated.
      enableFishIntegration = true;

      # ---- OUTPUT ---- #

      # Enable icons
      icons = "always";

      # Enable colors
      colors = "always";

      # Enable git
      git = true;

      # Extra flags appended to every eza invocation.
      # Examples: "--group-directories-first" "--header" "--octal-permissions"
      extraOptions = [ ];
    };

    # Keep existing user-owned theme and supporting files in place
    home.sessionVariables.EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
  };

  imports = [
    # ---- THEMES ---- #
    # Exactly one of these should be enabled.
    # `default-theme.nix` is eza's own default palette; it is named that
    # way so it is not mistaken for a folder aggregator.
    ./themes/black.nix
    ./themes/catppuccin-frappe.nix
    ./themes/catppuccin-latte.nix
    ./themes/catppuccin-macchiato.nix
    ./themes/catppuccin-mine.nix
    ./themes/catppuccin-mocha.nix
    ./themes/default-theme.nix
    ./themes/dracula.nix
    ./themes/frosty.nix
    ./themes/gruvbox-dark.nix
    ./themes/gruvbox-light.nix
    ./themes/one-dark.nix
    ./themes/rose-pine.nix
    ./themes/rose-pine-dawn.nix
    ./themes/rose-pine-moon.nix
    ./themes/solarized-dark.nix
    ./themes/tokyonight.nix
    ./themes/white.nix
    ./themes/yahddyyp-catppuccin.nix
  ];
}
