# shared/terminal/cli-tuis/default.nix
#
# CLI AND TUI TOOLS
# =====================================================================
# - Imports all command-line and terminal UI tool modules
# - Each tool owns its own macOS and Linux enable toggles
# - Imported by each host home module
# =====================================================================

{ ... }:
{
  imports = [
    ./atuin.nix

    # Bat settings and the theme selected in bat.nix
    ./bat/bat.nix

    # Btop settings and the theme selected in btop.nix
    ./btop/btop.nix

    ./delta.nix

    # Eza settings; its themes are imported from eza.nix
    ./eza/eza.nix

    ./fastfetch/fastfetch.nix
    ./fzf/fzf.nix
    ./ripgrep.nix
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
    ./zoxide.nix
  ];

}
