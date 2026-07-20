# /Users/ven/.config/nix/nix-config/shared/packages/media-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED MEDIA TOOLS
#
# Installs media packages shared between Darwin and Linux:
# - Media inspection tools
# - PDF rendering utilities
# - Shared media applications
#
# Each package provides:
# - A global enable or disable toggle
# - A Darwin installation toggle
# - A Linux installation toggle
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM DETECTION ------ #
  #
  # Determines which operating system is currently evaluating
  # this shared package module.
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ SHARED MEDIA PACKAGE DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the package exists at all.
  #
  # installOn.darwin:
  #   Controls whether the package is installed on macOS.
  #
  # installOn.linux:
  #   Controls whether the package is installed on Linux.
  # ------------------------------------------------------------
  # ---- Kiwix
  # Offline reader for ZIM archives and web content.
  kiwix = {
    enable = true;
  
    installOn = {
      darwin = true;
      linux = true;
    };
  
    package =
      if isDarwin then
        pkgs.kiwix-apple
      else if isLinux then
        pkgs.kiwix
      else
        throw "Kiwix is not configured for this platform";
  
    darwinLink = {
      enable = true;
      appName = "Kiwix.app";
      targetDirectory = "/Applications";
    };
  };
  
  mediaPackages = {
    # ---- MediaInfo
    # Inspects technical and tag information in media files.
    mediainfo = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.mediainfo;
    };

    # ---- Poppler
    # Provides command-line utilities for rendering and inspecting PDFs.
    poppler = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.poppler-utils;
    };

    # ---- YouTube Music Desktop
    # Provides the shared YouTube Music desktop application.
    ytmdesktop = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.ytmdesktop;
    };
  };

  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  #
  # Selects only packages that are enabled for the system that
  # is currently evaluating this module.
  # ------------------------------------------------------------

  enabledForCurrentSystem =
    mediaPackage:
      mediaPackage.enable
      && (
        (isDarwin && mediaPackage.installOn.darwin)
        || (isLinux && mediaPackage.installOn.linux)
      );

  enabledMediaPackages =
    map
      (mediaPackage: mediaPackage.package)
      (
        lib.filter
          enabledForCurrentSystem
          (lib.attrValues mediaPackages)
      );
in

{
  # ------------------------------------------------------------
  # ------ SHARED MEDIA PACKAGES ------ #
  #
  # Installs the filtered media package set for the current
  # Darwin or Linux system.
  # ------------------------------------------------------------

  environment.systemPackages = enabledMediaPackages;
}