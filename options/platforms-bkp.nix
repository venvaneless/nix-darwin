# options/platforms.nix
#
# =====================================================================
# OPTIONS: PLATFORM DETECTION
#
# Provides the shared platform checks used by package-list modules.
# =====================================================================

{ pkgs }:

{
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
}
