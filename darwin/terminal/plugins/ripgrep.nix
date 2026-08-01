# darwin/terminal/plugins/ripgrep.nix
#
# =====================================================================
# RIPGREP
# 
# Fast recursive search
# =====================================================================

{ config, ... }:

{
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
}
