# shared/home/default.nix
#
# =====================================================================
# SHARED HOME MANAGER
#
# Top-level glue for all shared Home Manager configuration.
# Imports:
#   - configuration shared by all platforms
#   - platform-specific Home Manager configuration
#   - Home Manager submodules such as services
# =====================================================================

{ pkgs, ... }:

let
  platforms = import ../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin;
in
{
  imports =
    [
      ./shared.nix
      ./services
    ]
    ++ (if isDarwin then [ ./darwin.nix ] else [ ]);
}