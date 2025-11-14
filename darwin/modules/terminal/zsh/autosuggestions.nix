# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/autosuggestions.nix
#
# ZSH: AUTOSUGGESTIONS
# ============================================================
# Adds zsh-autosuggestions plugin after everything else loads.
# ============================================================

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.zsh-autosuggestions ];

  programs.zsh.initContent = lib.mkAfter ''
    # --- Load zsh-autosuggestions plugin ---
    if [ -f "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
      source "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
      echo "[zsh] autosuggestions loaded"
    else
      echo "[zsh] autosuggestions missing"
    fi
  '';
}
