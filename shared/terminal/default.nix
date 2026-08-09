# shared/terminal/default.nix
#
# =====================================================================
# FISH: SHARED TERMINAL CONFIGURATION
#
# Common Fish configuration for Darwin, standalone Linux Home Manager,
# and integrated NixOS Home Manager hosts.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ---- PLATFORM DETECTION ---- #
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ---- COMMON FISH SHELL SETTINGS ---- #
  # Shared Fish settings formerly kept in core.nix.
  coreCfg = config.ven.features.terminal.fish.core;

  # ---- FISH FEATURE CATALOG ---- #
  # Hosts can override each group below at normal option priority.
  fishFeatures = {
    core = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    themes = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    aliases = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    git = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    nixProfile = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    commands = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    downloads = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };
  };

  enabledForCurrentSystem =
    feature:
    feature.enable && ((isDarwin && feature.installOn.darwin) || (isLinux && feature.installOn.linux));
in
{
  imports = [
    ./aliases
    ./commands
    ./fish-themes.nix
  ];

  options.ven.features.terminal.fish.core.enable = lib.mkEnableOption "shared Fish shell settings";

  options.ven.features.terminal.fish.commands.enable = lib.mkEnableOption "portable Fish commands";

  options.ven.features.terminal.nixConfigDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/nix/nix-config";
    description = "Path to the host's Nix configuration repository.";
  };

  # ---- FEATURE DEFAULTS ---- #
  config = lib.mkMerge [
    (lib.mkIf coreCfg.enable {
      programs.fish = {
        enable = true;

        # ---- PLUGINS ---- #
        plugins = [
          {
            # Plugin that allows for automatic pairing of brackets, quotes, etc.
            name = "autopair.fish";
            src = pkgs.fetchFromGitHub {
              owner = "jorgebucaran";
              repo = "autopair.fish";
              rev = "main";
              hash = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
            };
          }
        ];

        shellInit = ''
          # Hide default greeting
          set fish_greeting

          # Use a named Fish history file
          set -g fish_history ven

          # Direnv integration
          direnv hook fish | source
        '';

        interactiveShellInit = ''
          # Completions
          fish_default_key_bindings

          # Autosuggestions
          set -g fish_autosuggestion_enabled 1
        '';
      };

      home.sessionPath = [
        "${config.home.homeDirectory}/.local/bin"
      ];
    })

    {
      ven.features.terminal.fish = lib.mapAttrs (_: feature: {
        enable = lib.mkDefault (enabledForCurrentSystem feature);
      }) fishFeatures;
    }
  ];
}
