# options/cli/gh.nix
#
# =====================================================================
# GH
#
# Owns GitHub CLI's option shape, platform selection, and Home Manager
# implementation. shared/terminal/cli-tuis/default.nix assigns every
# user-facing GitHub CLI knob.
#
# Installation and settings are managed through Home Manager, which
# renders $XDG_CONFIG_HOME/gh/config.yml from the settings below.
#
# ---- hosts.yml is deliberately NOT managed ---- #
# gh stores its OAuth token in $XDG_CONFIG_HOME/gh/hosts.yml and rewrites
# that file on every `gh auth login`, `gh auth refresh`, and account
# switch. Home Manager can write it through programs.gh.hosts, but that
# would put the token in the world-readable Nix store and replace the
# file with a read-only symlink, which breaks every gh auth command.
# hosts.yml therefore stays user-owned and mutable. gh has no theme
# system, so there is no theme module here.
# =====================================================================

{ config, lib, platforms, ... }:

let
  cfg = config.home.shared.cli.gh;

  # ---- PLATFORM SELECTION ---- #
  # The shared CLI/TUI settings choose enablement and supported platforms.
  # This module uses the common selector instead of recreating it locally.
  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform cfg;
in
{
  options.home.shared.cli.gh = {
    enable = lib.mkEnableOption "GitHub CLI";

    installOn = {
      darwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure GitHub CLI on macOS.";
      };

      linux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure GitHub CLI on Linux.";
      };
    };

    enabledForCurrentPlatform = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether GitHub CLI is enabled for the Home Manager host currently being built.";
    };

    gitCredentialHelper = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Let GitHub CLI answer Git credential prompts.";
      };

      hosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "GitHub hosts for which GitHub CLI supplies Git credentials.";
      };
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "GitHub CLI settings written to config.yml, including aliases.";
    };
  };

  config = lib.mkMerge [
    {
      home.shared.cli.gh.enabledForCurrentPlatform = enabledForCurrentPlatform;
    }
    (lib.mkIf enabledForCurrentPlatform {
      programs.gh = {
        # Install gh and generate config.yml.
        enable = true;

        # Let gh answer git's credential prompts for GitHub remotes.
        gitCredentialHelper = cfg.gitCredentialHelper;

        # ---- SETTINGS ---- #
        # The shared CLI/TUI module owns all user-selected config.yml values.
        settings = cfg.settings;
      };
    })
  ];
}
