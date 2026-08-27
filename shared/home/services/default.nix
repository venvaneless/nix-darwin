# shared/home/services/default.nix
#
# =====================================================================
# SHARED HOME MANAGER: SERVICES
#
# Glue for shared user-level services.
# =====================================================================

{ pkgs, ... }:

let
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin;
in
{
  imports =
    if isDarwin then
      [ ./darwin.nix ]
    else
      [ ];
}