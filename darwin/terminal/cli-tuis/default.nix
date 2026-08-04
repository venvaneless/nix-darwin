# darwin/terminal/cli-tuis/default.nix
#
# CLI AND TUI TOOLS
# =====================================================================
# - Collects all command-line and terminal UI tool modules
# - Imported once by ../default.nix
# =====================================================================

{
  imports = [
    ./atuin.nix
    ./btop.nix
    ./delta.nix
    ./eza.nix
    ./fastfetch.nix
    ./fzf.nix
    ./ripgrep.nix
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
    ./zoxide.nix
  ];
}