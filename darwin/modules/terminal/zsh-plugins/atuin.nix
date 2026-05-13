# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/atuin.nix
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
    enableZshIntegration = true;
  };

  programs.zsh.sessionVariables = {
    # --- ATUIN_NOBIND
    # #### Prevent Atuin from automatically taking over keybindings.
    ATUIN_NOBIND = "true";
  };

  programs.zsh.initContent = ''
    # --- Ctrl-R
    # Clear any previous Ctrl-R binding first.
    bindkey -r '^R' 2>/dev/null

    # --- Ctrl-R -> atuin-search
    # #### Bind Ctrl-R to Atuin search.
    bindkey '^R' atuin-search
  '';
}
