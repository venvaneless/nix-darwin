# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/history-substring-search.nix
#
# ============================================================
# ZSH: HISTORY SUBSTRING SEARCH
# Zsh port of Fish shell's history search
# -----------------------------------------
# 
# ---- Keybindings
# -- Walk normal history when prompt is empty
# Up / Down arrows
# --Search matching history when text is typed
# Up / Down arrow
# 
# ---- NOTE
# - Uses terminal-aware key bindings
# ============================================================

{ ... }:

{
  programs.zsh.historySubstringSearch = {
    enable = true;

    # Fallback bindings
    searchUpKey = [ "^[[A" ];
    searchDownKey = [ "^[[B" ];
  };


  programs.zsh.initContent = ''
    # ---------- Keymap mode ---------- #

    # --- bindkey -e
    #### Use emacs-style keybindings unless you intentionally use vi mode.
    bindkey -e

    # ---------- Terminal-aware bindings ---------- #

    # --- terminfo Up
    #### Bind terminal-aware Up arrow to history substring search up.
    if [[ -n "''${terminfo[kcuu1]}" ]]; then
      bindkey "''${terminfo[kcuu1]}" history-substring-search-up
    fi

    # --- terminfo Down
    #### Bind terminal-aware Down arrow to history substring search down.
    if [[ -n "''${terminfo[kcud1]}" ]]; then
      bindkey "''${terminfo[kcud1]}" history-substring-search-down
    fi

    # ---------- Fallback bindings ---------- #

    # --- fallback ^[[A
    #### Bind common Up arrow escape sequence to history substring search up.
    bindkey '^[[A' history-substring-search-up

    # --- fallback ^[[B
    #### Bind common Down arrow escape sequence to history substring search down.
    bindkey '^[[B' history-substring-search-down

    # --- fallback ^[OA
    #### Bind alternate terminal Up arrow escape sequence to history substring search up.
    bindkey '^[OA' history-substring-search-up

    # --- fallback ^[OB
    #### Bind alternate terminal Down arrow escape sequence to history substring search down.
    bindkey '^[OB' history-substring-search-down
  '';
}