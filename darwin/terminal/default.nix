# darwin/terminal/default.nix
#
# FISH: DARWIN EXTRAS
# =====================================================================
# - Shared Fish configuration lives in shared/terminal
# - This module keeps only macOS-specific paths and helpers
# =====================================================================

{ ... }:

{
  imports = [
    ./fish-extras.nix
  ];
}
