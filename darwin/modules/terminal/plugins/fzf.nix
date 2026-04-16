# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fzf.nix
#
# FZF: STANDARD WIDGETS + COMMAND PICKER + HISTORY + FORGIT
# ============================================= ===============
# - fzf (HM-native integration)
# - zsh-fzf-tab (fzf UI on <TAB>)
# - zsh-fzf-history-search (fzf UI on Ctrl-L)
# - zsh-forgit (fzf-powered git helper functions)
#
# - Ctrl-F opens a command picker
# - Ctrl-L opens fzf history search
# - Keeps Ctrl-R free for Atuin
# - Keeps forgit because Linux does not define a conflicting behavior
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
  
    # ---------- zsh-fzf-history-search ---------- #
    if [ -f "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh"
    fi

    # ---------- forgit ---------- #
    if [ -f "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh" ]; then
      source "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh"
    else
      echo "forgit plugin not found!"
    fi

    # ---------- FZF: COMMAND PICKER ---------- #
    fzf_command_picker() {
      local selected
      selected=$(print -rl -- ''${(ok)commands} | fzf)
      if [[ -n "$selected" ]]; then
        LBUFFER="$selected"
      fi
      zle reset-prompt
    }
    zle -N fzf_command_picker

    # ---------- KEYBINDS ---------- #

    # Rebind history search from Ctrl-R to Ctrl-O
    
    bindkey -r '^O' 2>/dev/null
    bindkey '^O' fzf-history-widget

    # Bind Ctrl-F to command picker
    bindkey -r '^F' 2>/dev/null
    bindkey '^F' fzf_command_picker
  '';
}