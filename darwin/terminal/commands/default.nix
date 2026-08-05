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
    # Make script files executable
    ./chmod.nix
    
    # Download content from the web
    ./downloads.nix

    # Quick actions for managing files and folders
    ./files-folders.nix

    # macOS commands
    ./macos.nix

    # Managing macOS Trash
    ./trash.nix
  ];
}
