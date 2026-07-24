# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/ripgrep.nix
#
# =====================================================================
# RIPGREP
# 
# Fast recursive search
# =====================================================================

{ config, ... }:

{
  # Installs Ripgrep without generating a replacement configuration file.
  programs.ripgrep.enable = true;

  # Ripgrep loads a config file only when this variable is set.
  home.sessionVariables.RIPGREP_CONFIG_PATH =
    "${config.xdg.configHome}/ripgrep/config";

  programs.fish.shellAliases = {
    # --- grep -> rg
    # Use ripgrep instead of grep.
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
