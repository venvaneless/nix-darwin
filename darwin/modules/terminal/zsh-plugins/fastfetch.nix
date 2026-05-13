# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fastfetch.nix
#
# =====================================================================
# FASTFETCH
# 
# Feature-rich and performance oriented,
# neofetch like system information tool
# =====================================================================

{ ... }:

{
  programs.fastfetch.enable = true;

  programs.zsh.initContent = ''
    if [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1; then
      FASTFETCH_SESSION_MARKER="''${XDG_RUNTIME_DIR:-$TMPDIR}/fastfetch-shown-$USER"

      if [[ ! -e "$FASTFETCH_SESSION_MARKER" ]]; then
        fastfetch --config "$HOME/.config/fastfetch.jsonc"
        : > "$FASTFETCH_SESSION_MARKER"
      fi
    fi
  '';
}