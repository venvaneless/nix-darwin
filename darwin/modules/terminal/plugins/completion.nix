# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/completion.nix
#
# ZSH: COMPLETION SYSTEM (GLOBAL)
# ============================================================
# - Enables core Zsh completion
# - Runs compinit safely
# - Enables interactive completion menu
# - Loads Docker and other external completion scripts
# ============================================================

{ config, pkgs, ... }:

{
  # Enable core Zsh completion system
  programs.zsh.enableCompletion = true;

  # Global completion setup
  programs.zsh.initContent = ''
    # Disable insecure directory warnings from compinit
    ZSH_DISABLE_COMPFIX=true

    # Load the completion listing module required for menu selection
    zmodload zsh/complist

    # Build and load the completion system
    autoload -Uz compinit
    compinit -u

    # Enable interactive completion menu selection (fzf-style)
    zstyle ':completion:*' menu select

    # Prompt shown when multiple completion matches exist
    zstyle ':completion:*' list-prompt '%S%M matches:%s'

    # Prompt shown while scrolling through selectable matches
    zstyle ':completion:*' select-prompt '%SScrolling active: %s'

    # Press Enter to accept the currently selected completion item
    bindkey -M menuselect '^M' .accept-line

    #### EXTERNAL COMPLETIONS ####

    # Docker Desktop Zsh completion
    if [ -f "/Applications/Programming/Docker.app/Contents/Resources/etc/docker.zsh-completion" ]; then
      source "/Applications/Programming/Docker.app/Contents/Resources/etc/docker.zsh-completion"
    fi

    # Docker Compose completion
    if [ -f "/Applications/Programming/Docker.app/Contents/Resources/etc/docker-compose.zsh" ]; then
      source "/Applications/Programming/Docker.app/Contents/Resources/etc/docker-compose.zsh"
    fi

    # Add more external completions here if needed
    # if [ -f "/path/to/completion.zsh" ]; then
    #   source "/path/to/completion.zsh"
    # fi
  '';
}