# shared/terminal/cli-tuis/default.nix
#
# CLI AND TUI TOOLS
# =====================================================================
# - Collects all command-line and terminal UI tool modules
# - Imported by each host home module
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM DETECTION ------ #
  #
  # Determines which operating system is currently evaluating
  # this shared Home Manager module.
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ CLI AND TUI CATALOG ------ #
  #
  # enable:
  #   Controls the default activation of the tool.
  #
  # installOn.darwin:
  #   Enables the default on macOS.
  #
  # installOn.linux:
  #   Enables the default on Linux.
  #
  # Individual hosts can override each corresponding
  # ven.features.terminal.cliTuis.<tool>.enable option.
  # ------------------------------------------------------------

  cliTuis = {
    atuin = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    bat = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    btop = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    delta = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    eza = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    fastfetch = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    fzf = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    ripgrep = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    starship = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    tmux = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    yazi = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };

    zoxide = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };
    };
  };

  # ------------------------------------------------------------
  # ------ PLATFORM DEFAULTS ------ #
  #
  # Selects catalog entries enabled for the current platform.
  # These defaults have low priority so host modules can override them.
  # ------------------------------------------------------------

  enabledForCurrentSystem =
    cliTui:
    cliTui.enable && ((isDarwin && cliTui.installOn.darwin) || (isLinux && cliTui.installOn.linux));
in
{
  imports = [
    ./atuin.nix

    # Bat settings and the theme selected in bat.nix
    ./bat/bat.nix

    # Btop settings and the theme selected in btop.nix
    ./btop/btop.nix

    ./delta.nix

    # Eza settings; its themes are imported from eza.nix
    ./eza/eza.nix

    ./fastfetch.nix
    ./fzf/fzf.nix
    ./ripgrep.nix
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
    ./zoxide.nix
  ];

  config.ven.features.terminal.cliTuis = lib.mapAttrs (_: cliTui: {
    enable = lib.mkDefault (enabledForCurrentSystem cliTui);
  }) cliTuis;
}
