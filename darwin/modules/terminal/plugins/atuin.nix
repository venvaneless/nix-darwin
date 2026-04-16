# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/atuin.nix
#
# ============================================================
# ZSH: ATUIN
#
# Enables Atuin and hooks it into Zsh history search.
# ============================================================

{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

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

    # Keybindings
    # Ctrl-A = start of line
    # Ctrl-E = end of line
    # Ctrl-U = delete from cursor back to start
    # Ctrl-K = delete from cursor to end
    # Ctrl-W = delete previous word
    # Ctrl-L = clear screen
  '';
}
