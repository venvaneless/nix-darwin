# shared/terminal/commands/default.nix
#
# =====================================================================
# FISH: PORTABLE COMMANDS
# =====================================================================

{ ... }:

{
  imports = [
    ./chmod.nix
    ./files-folders.nix
    ./downloads.nix
  ];
}
