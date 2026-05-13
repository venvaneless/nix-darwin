# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/modules/ripgrep.nix
#
# =====================================================================
# RIPGREP
# 
# Fast recursive search
# =====================================================================

{ ... }:

{
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