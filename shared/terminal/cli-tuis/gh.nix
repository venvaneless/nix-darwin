# shared/terminal/cli-tuis/gh.nix
#
# =====================================================================
# GH
#
# GitHub CLI for pull requests, issues, releases, and API calls
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

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.gh;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Gh's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.gh.enable directly.
  gh = {
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
    gh.enable && ((isDarwin && gh.installOn.darwin) || (isLinux && gh.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.gh.enable = lib.mkEnableOption "GitHub CLI";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.gh.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      programs.gh = {
        # Install gh and generate config.yml.
        enable = true;

        # Let gh answer git's credential prompts for GitHub remotes.
        gitCredentialHelper = {
          enable = true;
          hosts = [
            "https://github.com"
            "https://gist.github.com"
          ];
        };

        # ---- SETTINGS ---- #
        # These reproduce the previous hand-written config.yml exactly.
        settings = {
          # Protocol used for clone, fork, and remote operations.
          git_protocol = "https";

          # Empty values keep gh deferring to the environment.
          editor = "";
          pager = "";
          browser = "";
          http_unix_socket = "";

          # Interactive prompting, in the terminal rather than an editor.
          prompt = "enabled";
          prefer_editor_prompt = "disabled";

          # Animated progress indicator.
          spinner = "enabled";

          # Accessibility and colour behaviour left at gh's defaults.
          # Set color_labels to "enabled" for truecolor issue labels.
          color_labels = "enabled";
          accessible_colors = "disabled";
          accessible_prompter = "disabled";

          # ---- ALIASES ---- #
          aliases = {
            # --- gh co -> gh pr checkout
            ## Check out the branch behind a pull request.
            co = "pr checkout";
          };
        };
      };
    })
  ];
}
