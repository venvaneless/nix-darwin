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
  # ---- SHARED PATHS ---- #
  # Only the home-relative fragments are used here; this module runs on
  # Darwin and Linux, so the home prefix stays dynamic.
  paths = import ../../options/paths.nix { };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;

  fish = {
    # Ghost text shown from Fish history and completions.
    autosuggestions.installOn = {
      darwin = true;
      linux = true;
    };

    # Pairs brackets and quotes while typing.
    plugins.autopair.installOn = {
      darwin = true;
      linux = true;
    };
  };

  enabledForCurrentSystem =
    feature:
    (isDarwin && feature.installOn.darwin) || (isLinux && feature.installOn.linux);
in
{
  imports = [
    ./aliases
    ./commands
    ./fish-themes.nix
  ];

  options.ven.features.terminal.nixConfigDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/${paths.relative.nixConfig}";
    description = "Path to the host's Nix configuration repository.";
  };

  config = {
    programs.fish = {
      enable = true;

      plugins = lib.optionals (enabledForCurrentSystem fish.plugins.autopair) [
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

        ${lib.optionalString (enabledForCurrentSystem fish.autosuggestions) ''
          # Autosuggestions
          set -g fish_autosuggestion_enabled 1
        ''}
      '';
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${paths.relative.localBin}"
      "${config.home.homeDirectory}/Documents/Obsidian/Ven/scripts"
    ];
  };
}
