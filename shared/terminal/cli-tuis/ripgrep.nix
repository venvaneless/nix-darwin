# shared/terminal/cli-tuis/ripgrep.nix
#
# =====================================================================
# RIPGREP
#
# Fast recursive search
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.ripgrep;
in
{
  options.ven.features.terminal.cliTuis.ripgrep.enable =
    lib.mkEnableOption "Ripgrep recursive search";

  config = lib.mkIf cfg.enable {
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
  };
}
