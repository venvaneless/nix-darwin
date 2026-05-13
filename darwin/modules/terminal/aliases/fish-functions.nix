# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/fish-functions.nix
#
# FISH FUNCTIONS
# =============================================================
# Custom reusable Fish shell functions
# 
# =============================================================
#
# ---- Git Helpers
# -- gm
# Stage everything, create commit, run darwin-rebuild switch
# =============================================================

{ ... }:

{
  programs.fish.functions = {

    # ---------------------------------------------------------
    # gm
    # ---------------------------------------------------------
    # Stages all changes
    # Creates a git commit using the provided message
    # Runs darwin-rebuild switch afterwards
    #
    # Example:
    # gm "Fixing fastfetch"
    # ---------------------------------------------------------
    gm = ''
      git add -A
      and git commit -m "$argv"
      and drs
    '';
  };
}