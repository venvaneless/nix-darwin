# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/autocomplete.nix
#
# ============================================================
# ZSH: COMPLETION SYSTEM (GLOBAL)
# - Tab shows selectable native zsh completion
# - keep layout compact
# - avoid broken footer color escapes
# ============================================================

{ ... }:

{
  programs.zsh.enableCompletion = true;

  programs.zsh.initContent = ''
    # Disable insecure directory warnings from compinit
    ZSH_DISABLE_COMPFIX=true
    
    # ---------- Load completion list module ---------- #
    zmodload zsh/complist

    # ---------- Load compinit ---------- #
    autoload -Uz compinit
    
    # ---------- Initialize completion system ---------- #
    compinit -u

    # ---------- Enable selectable menu completion ---------- #
    zstyle ':completion:*' menu select
    
    # ---------- Show descriptions ---------- #
    zstyle ':completion:*' verbose yes
    
    # ---------- Pack completion list tighter ---------- #
    zstyle ':completion:*' list-packed yes

    # ---------- Clean up double slashes ---------- #
    zstyle ':completion:*' squeeze-slashes yes

    # ---------- Case-insensitive matching ---------- #
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    
    # ---------- Hide group headers ---------- #
    zstyle ':completion:*' group-name ''''

    # ---------- Enable completion cache ---------- #
    zstyle ':completion:*' use-cache on

    # ---------- Set completion cache location ---------- #
    zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache"
    
    # ---------- More-rows footer text ---------- #
    zstyle ':completion:*' list-prompt '...and %m more rows'
    zstyle ':completion:*' list-prompt '%S%M matches:%s'
    
    # ---------- Menu-scroll footer text ---------- #
    zstyle ':completion:*' select-prompt '%SScrolling active: %s'
    
    # ---------- Format descriptions ---------- #
    zstyle ':completion:*:descriptions' format '(%d)'

    # ---------- Format completion messages ---------- #
    zstyle ':completion:*:messages' format '%d'

    # ---------- Format no-match warning ---------- #
    zstyle ':completion:*:warnings' format 'no matches found'

    # ---------- Color left-side completion entries ---------- #
    export ZLS_COLORS='fi=37:di=36:ex=97:ma=30;47:hi=30;47'

    # ---------- Bind Tab to menu select ---------- #
    bindkey '^I' menu-select

    # ---------- Bind up arrow in menu ---------- #
    bindkey -M menuselect '^[[A' up-line-or-history

    # ---------- Bind down arrow in menu ---------- #
    bindkey -M menuselect '^[[B' down-line-or-history

    # ---------- Bind right arrow in menu ---------- #
    bindkey -M menuselect '^[[C' forward-char

    # ---------- Bind left arrow in menu ---------- #
    bindkey -M menuselect '^[[D' backward-char

    # ---------- Bind Enter to accept selection ---------- #
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
  '';
}