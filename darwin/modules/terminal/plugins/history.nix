# /Users/ven/dotfiles/nix/darwin/modules/terminal/zsh/zsh/history.nix
#
# ZSH: HISTORY SUBSTRING SEARCH
# ============================================================

{ config, pkgs, ... }:

{
  programs.zsh.historySubstringSearch.enable = true;
}
