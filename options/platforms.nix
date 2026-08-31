# options/platforms.nix
#
# =====================================================================
# OPTIONS: PLATFORM DETECTION
#
# Provides the shared platform checks used by package-list modules.
# =====================================================================

{ pkgs }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM CHECKS ------ #
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ PACKAGE PLATFORM FILTERING ------ #
  # ------------------------------------------------------------

  enabledForCurrentPlatform = package:
    (package.enable or false)
    && (
      (isDarwin && (package.installOn.darwin or false))
      || (isLinux && (package.installOn.linux or false))
    );
in
{
  inherit isDarwin isLinux enabledForCurrentPlatform;
}
