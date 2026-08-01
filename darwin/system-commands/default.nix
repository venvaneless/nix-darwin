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
    ./ftar.nix
    ./generations-cleanup.nix
    ./rsync.nix
  ];
}