# options/cli/default.nix
#
# =====================================================================
# OPTIONS: CLI TOOLS
# =====================================================================
#
# Aggregates option modules for portable command-line tools. Shared
# terminal files assign knobs without importing individual option modules.
# =====================================================================

{ ... }:

{
  imports = [
    # Atuin's option interface, themes, and Home Manager implementation.
    ./atuin

    # Bat's option interface, themes, and Home Manager implementation.
    ./bat

    # GitHub CLI's option interface and Home Manager implementation.
    ./gh.nix

    # Micro's option interface and Home Manager implementation.
    ./micro

    # Neovim's option interface, themes, and generated Lua files.
    ./nvim

    # Television's option interface, channels, and Home Manager implementation.
    ./television
  ];
}
