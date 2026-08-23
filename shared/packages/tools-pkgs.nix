# shared/packages/tools-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED TOOLS
#
# Declares general-purpose tools for Darwin and Linux. Common helpers
# select packages by platform and create guarded Darwin app links.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  helpers = import ../../options { inherit lib options pkgs; };

  # ------------------------------------------------------------
  # ------ TOOL PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  toolPackages = {
    # ---- Espanso
    # Cross-platform text expander for keyboard-driven snippets.
    espanso = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.espanso;
      appName = "Espanso.app";
      symlinkTools = true;
    };
  };
in
helpers.packageOptions.mkPackageModule {
  name = "shared-tools";
  packages = toolPackages;
}
