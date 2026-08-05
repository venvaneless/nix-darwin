# darwin/system-commands/default.nix
#
# =====================================================================
# SYSTEM COMMANDS
#
# Imports custom command-line applications installed system-wide
# =====================================================================

{ ... }:

{
  imports = [
    ./backups
    ./fmove.nix
    ./ftar.nix
    ./generations-cleanup.nix
  ];
}
