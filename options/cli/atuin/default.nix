# options/cli/atuin/default.nix
#
# =====================================================================
# ATUIN
#
# Owns Atuin's option shape, platform selection, Home Manager
# implementation, and theme files. shared/terminal/cli-tuis/default.nix
# assigns every user-facing Atuin knob.
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

{ config, lib, platforms, ... }:

let
  cfg = config.cli.atuin;

  # ---- PLATFORM SELECTION ---- #
  # The shared CLI/TUI settings choose enablement and supported platforms.
  # This module uses the common selector instead of recreating it locally.
  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform cfg;

  # ---- ACTIVE THEMES ---- #
  # Atuin reads one theme name from config.toml, so its theme toggles are
  # mutually exclusive.
  enabledThemes = lib.attrNames (lib.filterAttrs (_: theme: theme.enable) cfg.themes);
in
{
  options.cli.atuin = {
    enable = lib.mkEnableOption "Atuin shell history";

    installOn = {
      darwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure Atuin on macOS.";
      };

      linux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure Atuin on Linux.";
      };
    };

    enabledForCurrentPlatform = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether Atuin is enabled for the Home Manager host currently being built.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Atuin settings written to config.toml.";
    };

    fish = {
      preventAutomaticKeybindings = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Prevent Atuin from replacing Fish keybindings automatically.";
      };

      searchBinding = lib.mkOption {
        type = lib.types.str;
        default = "\\cr";
        description = "Fish key sequence bound to Atuin history search.";
      };
    };
  };

  config = lib.mkMerge [
    {
      cli.atuin.enabledForCurrentPlatform = enabledForCurrentPlatform;
    }
    (lib.mkIf enabledForCurrentPlatform {
    # ---- CONFLICTING THEMES ---- #
    assertions = [
      {
        assertion = lib.length enabledThemes <= 1;
        message = ''
          atuin: only one theme may be enabled at a time, but these are on:
          ${lib.concatStringsSep ", " enabledThemes}

          Disable the others under
          cli.atuin.themes.<name>.enable.
        '';
      }
    ];

    programs.atuin = {
      # Install and enable atuin and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;

      # The shared CLI/TUI module owns all user-selected config.toml values.
      settings = cfg.settings;
    };

    programs.fish.shellInit = lib.optionalString cfg.fish.preventAutomaticKeybindings ''
      # --- ATUIN_NOBIND
      # Prevent Atuin from automatically taking over keybindings.
      set -gx ATUIN_NOBIND true
    '';

    programs.fish.interactiveShellInit = ''
      # --- Ctrl-R
      # Bind Ctrl-R to Atuin search.
      bind ${cfg.fish.searchBinding} _atuin_search
    '';
    })
  ];

  imports = [
    # ---- THEMES ---- #
    # Exactly one may be enabled.
    ./themes/catppuccin-mocha-mauve.nix
    ./themes/gruvbox-dark.nix
  ];
}
