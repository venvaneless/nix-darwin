# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/plugins/fzf.nix
#
# =====================================================================
# FZF
# Command-line fuzzy finder written in Go
# -----------------------------------------
# 
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
# =====================================================================

{ ... }:

{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

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
      "--color=bg+:#2a273f,bg:#232136,spinner:#f6c177,hl:#ea9a97"
      "--color=fg:#e0def4,header:#ea9a97,info:#9ccfd8,pointer:#c4a7e7"
      "--color=marker:#eb6f92,fg+:#e0def4,prompt:#c4a7e7,hl+:#ea9a97"
    ];
  };

  programs.fish.interactiveShellInit = ''
    # FISH: FZF KEYBINDS
    # =========================
    # Tab    = normal Fish completion
    # Ctrl-F = fuzzy command picker
    # Ctrl-L = fuzzy history picker

    function __ven_fzf_history
      set -l selected (history | fzf)

      if test -n "$selected"
        commandline -r -- $selected
      end

      commandline -f repaint
    end

    function __ven_fzf_command_picker
      set -l selected (complete -C "" | awk '{print $1}' | sort -u | fzf)

      if test -n "$selected"
        commandline -r -- $selected
      end

      commandline -f repaint
    end

    bind \cf __ven_fzf_command_picker
    bind \cl __ven_fzf_history
  '';
}