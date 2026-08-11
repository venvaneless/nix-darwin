# shared/terminal/cli-tuis/fzf/fzf.nix
#
# =====================================================================
# FZF
# Command-line fuzzy finder written in Go
# =====================================================================
#
# The common interaction settings live here. The selected colour
# palette is owned by fzf-themes.nix and its individual theme modules.
#
# ---- Keybindings
# Ctrl-F: command picker
# Ctrl-L: history picker
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.fzf;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Fzf's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.fzf.enable directly.
  fzf = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    fzf.enable && ((isDarwin && fzf.installOn.darwin) || (isLinux && fzf.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.fzf.enable = lib.mkEnableOption "Fzf fuzzy finder";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.fzf.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
    programs.fzf = {
      # Install and enable fzf and integrate it with Fish shell.
      enable = true;
      enableFishIntegration = true;

      # ---- COMMON OPTIONS ---- #
      defaultOptions = [
        # Fit the picker into forty percent of the terminal window.
        "--height=40%"

        # Put the prompt and newest entries at the bottom.
        "--layout=reverse"

        # Use the shared visual treatment regardless of theme.
        "--border=rounded"
        "--info=inline"
        "--prompt=❯ "
        "--pointer=▸"
        "--marker=✓"
        "--scrollbar=▌"
        "--preview-window=right,60%,border-left"
      ];
    };

    programs.fish.interactiveShellInit = ''
      # ---- KEYBINDINGS ---- #
      # Tab    = normal Fish completion
      # Ctrl-F = fuzzy command picker
      # Ctrl-L = fuzzy history picker

      function __ven_fzf_history
        set -l selected (history | fzf)

        if test -n "$selected"
          commandline -r -- $selected
        end

        commandline -f repaint
      end

      function __ven_fzf_command_picker
        set -l selected (complete -C "" | awk '{print $1}' | sort -u | fzf)

        if test -n "$selected"
          commandline -r -- $selected
        end

        commandline -f repaint
      end

      bind \cf __ven_fzf_command_picker
      bind \cl __ven_fzf_history
    '';
    })
  ];

  imports = [
    ./fzf-themes.nix
  ];
}
