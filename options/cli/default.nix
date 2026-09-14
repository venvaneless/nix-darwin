# options/cli/default.nix
#
# =====================================================================
# OPTIONS: CLI TOOLS
# =====================================================================
#
# Aggregates option modules for portable command-line tools. Shared CLI/TUI
# files assign their knobs without importing individual option modules.
# =====================================================================

{ ... }:

{
  imports = [
    # Atuin's option interface, themes, and Home Manager implementation.
    ./atuin

    # GitHub CLI's option interface and Home Manager implementation.
    ./gh.nix

    # Micro's option interface and Home Manager implementation.
    ./micro
  ];
}
