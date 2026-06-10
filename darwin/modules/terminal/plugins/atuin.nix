# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/atuin.nix
#
# =====================================================================
# ATUIN
# 
# Improved shell history for zsh, bash, fish and nushell
# -----------------------------------------
# 
# ---- Keybindings
# -- Start of line
# Ctrl-A
# -- End of line
# Ctrl-E
# -- Delete from cursor back to start
# Ctrl-U
# -- Delete from cursor to end
# Ctrl-K
# -- Delete previous word
# Ctrl-W
# -- Clear screen
# Ctrl-L
# =====================================================================

{ ... }:

{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish.shellInit = ''
    # --- ATUIN_NOBIND
    # Prevent Atuin from automatically taking over keybindings.
    set -gx ATUIN_NOBIND true
  '';

  programs.fish.interactiveShellInit = ''
    # --- Ctrl-R
    # Bind Ctrl-R to Atuin search.
    bind \cr _atuin_search
  '';
}