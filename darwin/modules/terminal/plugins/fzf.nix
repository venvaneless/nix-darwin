# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fzf.nix
#
# FZF
# =============================================================
# ---- Plugins
# - zsh-fzf-tab: fzf UI on <TAB>
# - zsh-fzf-history-search
# - zsh-forgit: fzf-powered git helper functions
#
# ---- Theme
#  Rosé Pine Moon theme sourced from upstream repo
#
# ---- Keybindings
# -- Command picker
# Ctrl-F
# -- fzf history search
# Ctrl-O 
# =============================================================

{ pkgs, lib, ... }:

# ---------- Theme Source ---------- #
let
  # Rosé Pine FZF Theme
  rosePineFzf = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "fzf";
    rev = "main";
    hash = "sha256-WKREw1qzjuURqrCS6LI5ySc924W8d2n0rlA6AV1K5OE=";
  };
in
{
  # ---------- FZF Configuration ---------- #
  programs.fzf = {
    enable = true;

    # Default Options
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

  # ---------- Plugin Packages ---------- #
  home.packages = [
    pkgs.zsh-fzf-tab
    pkgs.zsh-fzf-history-search
    pkgs.zsh-forgit
  ];

  # ---------- Zsh Integration ---------- #
  programs.zsh.initContent = ''
    #### FZF-RELATED PLUGINS ####

    # ---------- Theme ---------- #
    # Rosé Pine Moon theme for fzf
    if [ -f "${rosePineFzf}/dist/rose-pine-moon.sh" ]; then
      source "${rosePineFzf}/dist/rose-pine-moon.sh"
    else
      echo "Rosé Pine Moon fzf theme not found!"
    fi

    # ---------- fzf-tab ---------- #
    # Use fzf for <TAB> completion
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

    # ---------- History Search ---------- #
    # zsh-fzf-history-search
    if [ -f "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search/history-search.plugin.zsh"
    elif [ -f "${pkgs.zsh-fzf-history-search}/share/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/history-search.plugin.zsh"
    elif [ -f "${pkgs.zsh-fzf-history-search}/share/zsh/plugins/zsh-fzf-history-search/history-search.plugin.zsh" ]; then
      source "${pkgs.zsh-fzf-history-search}/share/zsh/plugins/zsh-fzf-history-search/history-search.plugin.zsh"
    fi

    # ---------- Forgit ---------- #
    # zsh-forgit
    if [ -f "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh" ]; then
      source "${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh"
    else
      echo "forgit plugin not found!"
    fi

    # ---------- Command Picker ---------- #
    # FZF command picker widget
    fzf_command_picker() {
      local selected
      selected=$(print -rl -- ''${(ok)commands} | fzf)
      if [[ -n "$selected" ]]; then
        LBUFFER="$selected"
      fi
      zle reset-prompt
    }
    zle -N fzf_command_picker

    # ---------- Keybindings ---------- #
    # Custom FZF keybinds

    # Rebind history search from Ctrl-R to Ctrl-O
    bindkey -r '^O' 2>/dev/null
    bindkey '^O' fzf-history-widget

    # Bind Ctrl-F to command picker
    bindkey -r '^F' 2>/dev/null
    bindkey '^F' fzf_command_picker
  '';
}