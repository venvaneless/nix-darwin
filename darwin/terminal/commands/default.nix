# darwin/terminal/commands/default.nix
#
# =====================================================================
# COMMANDS
#
# Imports reusable Fish commands and functions
# =====================================================================

{ ... }:

{
  imports = [
    # macOS Obsidian library recovery helpers
    ./downloads.nix

    # iCloud folder navigation and ditto-backed copying
    ./files-darwin.nix

    # macOS commands
    ./macos.nix

    # Managing macOS Trash
    ./trash.nix
  ];
}
