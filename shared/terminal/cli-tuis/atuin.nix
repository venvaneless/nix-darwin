# shared/terminal/cli-tuis/atuin.nix
#
# =====================================================================
# ATUIN
#
# Improved shell history for zsh, bash, fish and nushell.
# Theme definitions live in their own modules so one palette can be
# selected declaratively at a time.
# -----------------------------------------
#
# ---- Keybindings
# -- Start of line
# Ctrl-A
# -- End of line
# Ctrl-E
# -- Delete from cursor back to start
# Ctrl-U
# -- Delete from cursor to end
# Ctrl-K
# -- Delete previous word
# Ctrl-W
# -- Clear screen
# Ctrl-L
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.atuin;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Atuin's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.atuin.enable directly.
  atuin = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    atuin.enable && ((isDarwin && atuin.installOn.darwin) || (isLinux && atuin.installOn.linux));

  # ---- ACTIVE THEMES ---- #
  # Atuin reads one theme name from config.toml, so its theme toggles are
  # mutually exclusive.
  enabledThemes = lib.attrNames (lib.filterAttrs (_: theme: theme.enable) cfg.themes);
in
{
  options.ven.features.terminal.cliTuis.atuin.enable = lib.mkEnableOption "Atuin shell history";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.atuin.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
    # ---- CONFLICTING THEMES ---- #
    assertions = [
      {
        assertion = lib.length enabledThemes <= 1;
        message = ''
          atuin: only one theme may be enabled at a time, but these are on:
          ${lib.concatStringsSep ", " enabledThemes}

          Disable the others under
          ven.features.terminal.cliTuis.atuin.themes.<name>.enable.
        '';
      }
    ];

    programs.atuin = {
      # Install and enable atuin and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;

      # ---- PRESERVED SETTINGS ---- #
      # These are the two effective settings from the archived config.toml.
      settings = {
        enter_accept = true;

        sync = {
          # Keep Atuin sync-v2 records enabled for existing history data.
          records = true;
        };
      };
    };

    programs.fish.shellInit = ''
      # --- ATUIN_NOBIND
      # Prevent Atuin from automatically taking over keybindings.
      set -gx ATUIN_NOBIND true
    '';

    programs.fish.interactiveShellInit = ''
      # --- Ctrl-R
      # Bind Ctrl-R to Atuin search.
      bind \cr _atuin_search
    '';
    })
  ];

  imports = [
    # ---- THEMES ---- #
    # Exactly one may be enabled.
    ./atuin/themes/catppuccin-mocha-mauve.nix
    ./atuin/themes/gruvbox-dark.nix
  ];
}
