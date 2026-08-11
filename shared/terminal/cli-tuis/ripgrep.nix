# shared/terminal/cli-tuis/ripgrep.nix
#
# =====================================================================
# RIPGREP
#
# Fast recursive search
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.ripgrep;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Ripgrep's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.ripgrep.enable directly.
  ripgrep = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    ripgrep.enable && ((isDarwin && ripgrep.installOn.darwin) || (isLinux && ripgrep.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.ripgrep.enable =
    lib.mkEnableOption "Ripgrep recursive search";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.ripgrep.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
    # Install and enable ripgrep w/o config file generated
    programs.ripgrep.enable = true;

    # Loading a config file only when this variable is set.
    home.sessionVariables.RIPGREP_CONFIG_PATH =

      # Load a custom config file if it exists
      "${config.xdg.configHome}/ripgrep/config";

    programs.fish.shellAliases = {
      # ---- KEYBINDINGS ---- #

      # --- grep -> rg
      # Use ripgrep instead of grep
      grep = "rg --color=auto";

      # --- erg -> rg
      # Extended regex search.
      erg = "rg --color=auto";

      # --- frg -> rg -F
      # Fixed-string search.
      frg = "rg -F --color=auto";

      # --- fgrep -> rg -F
      # Fixed-string search compatibility alias.
      fgrep = "rg -F --color=auto";
    };
    })
  ];
}
