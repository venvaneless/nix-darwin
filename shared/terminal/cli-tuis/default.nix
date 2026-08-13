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

    # Delta settings and the theme selected in delta.nix
    ./delta/delta.nix

    # Eza settings; its themes are imported from eza.nix
    ./eza/eza.nix

    ./fastfetch/fastfetch.nix

    # Fd settings, its ignore file, and the theme selected in fd.nix
    ./fd/fd.nix

    ./fzf/fzf.nix
    ./gh.nix

    # Micro settings and the theme selected in micro.nix
    ./micro/micro.nix

    ./pet.nix
    ./ripgrep.nix
    ./starship.nix

    # Television settings and the theme selected in television.nix
    ./television/television.nix

    ./tmux.nix
    ./yazi.nix
    ./zoxide.nix
  ];

}
