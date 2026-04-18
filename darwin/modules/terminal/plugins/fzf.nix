# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fzf.nix
#
# FZF: STANDARD WIDGETS + COMMAND PICKER + HISTORY + FORGIT
# ============================================================
# - fzf (HM-native integration)
# - zsh-fzf-tab (fzf UI on <TAB>)
# - zsh-fzf-history-search (fzf UI on Ctrl-O)
# - zsh-forgit (fzf-powered git helper functions)
# - Rosé Pine Moon theme sourced from upstream repo
#
# - Ctrl-F opens a command picker
# - Ctrl-O opens fzf history search
# - Keeps Ctrl-R free for Atuin
# ============================================================

{ pkgs, lib, ... }:

let
  rosePineFzf = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "fzf";
    rev = "main";
    hash = sha256-WKREw1qzjuURqrCS6LI5ySc924W8d2n0rlA6AV1K5OE=;
  };
in
{
  programs.fzf = {
    enable = true;

    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border=rounded"
      "--info=inline"
      "--prompt=❯ "
      "--pointer=▸"
      "--marker=✓"
      "--scrollbar=▌"
      "--preview-window=right,60%,border-left"
    ];
  };

  home.packages = [
    pkgs.zsh-fzf-tab
    pkgs.zsh-fzf-history-search
    pkgs.zsh-forgit
  ];

  programs.zsh.initContent = ''
    #### FZF-RELATED PLUGINS ####

    # ----- Rosé Pine Moon theme for fzf -----
    if [ -f "${rosePineFzf}/dist/rose-pine-moon.sh" ]; then
      source "${rosePineFzf}/dist/rose-pine-moon.sh"
    else
      echo "Rosé Pine Moon fzf theme not found!"
    fi

    # ----- fzf-tab: use fzf for <TAB> completion -----
    if [ -f "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
    elif [ -f "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/zsh/plugins/fzf-tab/fzf-tab.zsh"
    elif [ -f "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
    elif [ -f "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.zsh" ]; then
      source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.zsh"
    else
      echo "fzf-tab plugin not found!"
    fi

    # ---------- zsh-fzf-history-search ---------- #
    if [ -f "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh"
    else
      echo "zsh-fzf-history-search plugin not found!"
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