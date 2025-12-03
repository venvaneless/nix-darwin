# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fzf.nix
#
# FZF + TAB + HISTORY + FORGIT
# ============================================================
# - fzf (HM-native integration)
# - zsh-fzf-tab (fzf UI on <TAB>)
# - zsh-fzf-history-search (fzf UI on Ctrl-R)
# - zsh-forgit (fzf-powered git helper functions)
# ============================================================

{ pkgs, ... }:

{
  # --- FZF core integration ---
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- Plugin packages ---
  home.packages = [
    pkgs.zsh-fzf-tab
    pkgs.zsh-fzf-history-search
    pkgs.zsh-forgit
  ];

  # --- Plugin sourcing (multiple path fallbacks, HM-compatible) ---
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

    # ----- zsh-fzf-history-search: Ctrl-R history -----
    if [ -f "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh"
    fi

    # ----- forgit: git helpers on top of fzf -----
    if [ -f "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh" ]; then
      source "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh"
    else
      echo "forgit plugin not found!"
    fi
  '';
}
