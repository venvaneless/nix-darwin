# /Users/ven/dotfiles/nix/darwin/modules/terminal/plugins/fzf.nix
#
# FZF + TAB + HISTORY + FORGIT
# ============================================================
# - fzf (HM-native integration)
# - zsh-fzf-tab
# - zsh-fzf-history-search
# - zsh-forgit
# ============================================================

{ pkgs, ... }:

{
  # --- HM-native fzf support ---
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- Plugin packages (as in your originals) ---
  home.packages = [
    pkgs.zsh-fzf-tab
    pkgs.zsh-fzf-history-search
    pkgs.zsh-forgit
  ];

  # --- Plugin sourcing (original syntax preserved) ---
  programs.zsh.initContent = ''
    # fzf-tab (original-style source path)
    if [ -f "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.zsh" ]; then
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.zsh
    fi

    # zsh-fzf-history-search (original-style source path)
    if [ -f "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source ${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh
    fi

    # forgit (original-style source path)
    if [ -f "${pkgs.zsh-forgit}/share/zsh/site-functions/forgit.plugin.zsh" ]; then
      source ${pkgs.zsh-forgit}/share/zsh/site-functions/forgit.plugin.zsh
    fi
  '';
}
