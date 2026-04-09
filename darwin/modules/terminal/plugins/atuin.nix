# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/atuin.nix
# 
# ZSH: ATUIN
# ============================================================
# Enables Atuin and hooks it into Zsh history search.
# ============================================================

{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    flags = [
      "--disable-up-arrow"
      "--disable-ctrl-r"
    ];
  };

  programs.zsh.initContent = ''
    bindkey -r '^R' 2>/dev/null
    bindkey '^R' atuin-search
  '';
}