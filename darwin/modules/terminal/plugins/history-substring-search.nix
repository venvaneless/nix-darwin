# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/history-substring-search.nix
#
# ZSH: HISTORY SUBSTRING SEARCH
# =========================
# Lets up/down search history by current typed substring.

{ ... }:

{
  programs.zsh.historySubstringSearch = {
    enable = true;

    # Fallback bindings
    searchUpKey = [ "^[[A" ];
    searchDownKey = [ "^[[B" ];
  };

  programs.zsh.initContent = ''
    # Use emacs-style keybindings
    bindkey -e
  
    # Terminal-aware arrow bindings
    if [[ -n "''${terminfo[kcuu1]}" ]]; then
      bindkey "''${terminfo[kcuu1]}" history-substring-search-up
    fi
  
    if [[ -n "''${terminfo[kcud1]}" ]]; then
      bindkey "''${terminfo[kcud1]}" history-substring-search-down
    fi
  
    # Extra fallback bindings
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
  '';
}