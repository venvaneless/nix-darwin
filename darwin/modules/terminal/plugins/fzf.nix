# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fzf.nix
#
# FZF + TAB + HISTORY + FORGIT
# ============================================================
# - fzf (HM-native integration)
# - zsh-fzf-tab (fzf UI on <TAB>)
# - zsh-fzf-history-search (fzf UI on Ctrl-L)
# - zsh-forgit (fzf-powered git helper functions)
# ============================================================

{ pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = [
    pkgs.zsh-fzf-tab
    pkgs.zsh-fzf-history-search
    pkgs.zsh-forgit
  ];

  programs.zsh.initContent = ''
    #### FZF-RELATED PLUGINS ####

    # ----- fzf-tab: use fzf for <TAB> completion -----
    if [ -f "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
    elif [ -f "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.zsh"
    elif [ -f "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
    elif [ -f "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.zsh"
    fi

    # ----- zsh-fzf-history-search -----
    if [ -f "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh"
    fi

    # Rebind history search from Ctrl-R to Ctrl-L
    bindkey -r '^R' 2>/dev/null
    bindkey -r '^L' 2>/dev/null
    bindkey '^L' fzf-history-widget

    # ----- forgit -----
    if [ -f "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh" ]; then
      source "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh"
    else
      echo "forgit plugin not found!"
    fi
  '';
}