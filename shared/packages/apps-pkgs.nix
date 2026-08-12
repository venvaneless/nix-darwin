# shared/packages/apps-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED GENERAL APPS
#
# Declares broad applications that do not belong in a more specific
# package category. Platform and Darwin-link behavior stays shared.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  helpers = import ../../options { inherit lib options pkgs; };

  # ------------------------------------------------------------
  # ------ GENERAL APPLICATION DEFINITIONS ------ #
  # ------------------------------------------------------------

  appPackages = {
    # ---- LibreWolf
    # Privacy-focused Firefox-derived web browser.
    librewolf = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.librewolf;
      appName = "LibreWolf.app";
      symlinkApplications = true;
    };
  };
in
helpers.packageOptions.mkPackageModule {
  name = "shared-apps";
  packages = appPackages;
}
