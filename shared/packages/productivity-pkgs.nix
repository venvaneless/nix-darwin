# shared/packages/productivity-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED PRODUCTIVITY TOOLS
#
# Declares productivity packages for Darwin and Linux. Common helpers
# select the active platform and create guarded Darwin app links.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  helpers = import ../../options { inherit lib options pkgs; };

  # ------------------------------------------------------------
  # ------ PRODUCTIVITY PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  productivityPackages = {
    # ---- Obsidian
    # Knowledge base and note-taking application with Markdown support.
    obsidian = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.obsidian;
      appName = "Obsidian.app";
      symlinkProductivity = true;
    };

    # ---- Vesktop
    # Alternate Discord client with Vencord built in.
    vesktop = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vesktop;
      appName = "Vesktop.app";
      symlinkProductivity = true;
    };

    # ---- Signal Desktop
    # Private messenger linked to the Signal mobile application.
    signalDesktop = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.signal-desktop;
      appName = "Signal.app";
      symlinkProductivity = true;
    };

    # ---- Signal Export
    # Command-line tool that exports Signal chats to Markdown.
    signalExport = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.signal-export;
    };
  };
in
helpers.packageOptions.mkPackageModule {
  name = "shared-productivity";
  packages = productivityPackages;
}
