# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/history-substring-search.nix
#
# ZSH: HISTORY SUBSTRING SEARCH
# =========================
# Lets up/down search history by current typed substring.

{ ... }:

{
  programs.zsh = {
    historySubstringSearch.enable = true;
  };
}