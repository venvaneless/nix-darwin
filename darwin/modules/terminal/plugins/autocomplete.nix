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
    
    # Load the completion listing module required for menu selection
    zmodload zsh/complist

    # Build and load the completion system
    autoload -Uz compinit
    # Initialize completion system
    compinit -u

    # Enable interactive completion menu selection (fzf-style)
    #### Makes completion open a selectable list/menu
    zstyle ':completion:*' menu select

    # ---------- Show descriptions ---------- #
    # Displays command descriptions when available
    zstyle ':completion:*' verbose yes

    # ---------- Pack completion list tighter ---------- #
    # Makes the list more compact vertically
    zstyle ':completion:*' list-packed yes

    # ---------- Clean up double slashes ---------- #
    # Keeps path completions cleaner
    zstyle ':completion:*' squeeze-slashes yes

    # ---------- Case-insensitive matching ---------- #
    # Lets uppercase/lowercase match each other
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

    # ---------- Hide group headers ---------- #
    # Avoids extra visible completion group labels when possible
    zstyle ':completion:*' group-name ''

    # ---------- Enable completion cache ---------- #
    # Speeds up repeated completion lookups
    zstyle ':completion:*' use-cache on

    # ---------- Set completion cache location ---------- #
    # Stores cached completion data here
    zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache"
    
    # Prompt shown when multiple completion matches exist
    zstyle ':completion:*' list-prompt '%S%M matches:%s'

    # Prompt shown while scrolling through selectable matches
    zstyle ':completion:*' select-prompt '%SScrolling active: %s'
    
    # ---------- More-rows footer text ---------- #
    # Shown when the completion list is longer than the visible area
    zstyle ':completion:*' list-prompt '...and %m more rows'

    # ---------- Menu-scroll footer text ---------- #
    # Shown while moving inside the completion menu
    zstyle ':completion:*' select-prompt 'Scrolling active: '

    # ---------- Format descriptions ---------- #
    # Wraps right-side descriptions in parentheses
    zstyle ':completion:*:descriptions' format '(%d)'

    # ---------- Format completion messages ---------- #
    # Controls generic completion message text
    zstyle ':completion:*:messages' format '%d'

    # ---------- Format no-match warning ---------- #
    # Controls the text shown when nothing matches
    zstyle ':completion:*:warnings' format 'no matches found'

    # ---------- Color left-side completion entries ---------- #
    # Styles completion entries on the left column
    export ZLS_COLORS='fi=37:di=36:ex=97:ma=30;47:hi=30;47'

    # ---------- Bind Tab to menu select ---------- #
    # Makes Tab open/use the selectable completion menu
    bindkey '^I' menu-select

    # ---------- Bind up arrow in menu ---------- #
    # Moves up inside the completion menu
    bindkey -M menuselect '^[[A' up-line-or-history

    # ---------- Bind down arrow in menu ---------- #
    # Moves down inside the completion menu
    bindkey -M menuselect '^[[B' down-line-or-history

    # ---------- Bind right arrow in menu ---------- #
    # Moves right inside the completion menu context
    bindkey -M menuselect '^[[C' forward-char

    # ---------- Bind left arrow in menu ---------- #
    # Moves left inside the completion menu context
    bindkey -M menuselect '^[[D' backward-char

    # Accepts the currently highlighted completion
    bindkey -M menuselect '^M' .accept-line
    #### Press Enter to accept the currently selected completion item
    bindkey -M menuselect '^M' .accept-line

    # #### EXTERNAL COMPLETIONS ####

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