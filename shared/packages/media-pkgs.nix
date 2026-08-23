# shared/packages/media-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED MEDIA TOOLS
#
# Declares media packages for Darwin and Linux. Common helpers select
# packages and provide safe Darwin application-category links.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  packageOptions = (import ../../options { inherit lib options pkgs; }).packageOptions;

  # ------------------------------------------------------------
  # ------ MEDIA PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  mediaPackages = {
    # ---- Kiwix
    # Offline content reader with platform-specific application bundles.
    kiwix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = packageOptions.byPlatform {
        darwin = pkgs.kiwix-apple;
        linux = pkgs.kiwix;
      };
      appName = "Kiwix.app";
      symlinkMultimedia = true;
    };

    # ---- MediaInfo
    # Inspects technical and tag information in media files.
    mediainfo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.mediainfo;
    };

    # ---- Poppler
    # Provides command-line utilities for rendering and inspecting PDFs.
    poppler = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.poppler-utils;
    };

    # ---- YouTube Music Desktop
    # Shared desktop application for YouTube Music.
    ytmdesktop = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.ytmdesktop;
      appName = "YouTube Music Desktop App.app";
      symlinkMultimedia = true;
    };
  };
in
packageOptions.mkPackageModule {
  name = "shared-media";
  packages = mediaPackages;
}
