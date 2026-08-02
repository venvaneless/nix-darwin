# darwin/packages/media-pkgs.nix
#
# =====================================================================
# PACKAGES: DARWIN MEDIA
#
# Installs macOS media applications and creates categorized links in:
# /Applications/Multimedia
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ MEDIA PACKAGE SETTINGS ------ #
  # Important package-group paths and behavior
  # ------------------------------------------------------------

  mediaApplicationSourceDirectory = "/Applications/Nix Apps";

  mediaApplicationTargetDirectory = "/Applications/Multimedia";

  mediaLinkManagerName = "manage-darwin-media-application-links";


  # ------------------------------------------------------------
  # ------ MEDIA APPLICATION DEFINITIONS ------ #
  #
  # enable:
  #   Installs or removes the package.
  #
  # link:
  #   Creates or removes its categorized application link.
  #
  # appName:
  #   Application bundle name inside /Applications/Nix Apps.
  #
  # All GUI applications in this file are linked into:
  # /Applications/Multimedia
  # ------------------------------------------------------------

  darwinMediaApplications = {
    # ---- VLC
    # Plays video, audio, streams, discs, and many media formats.
    vlc = {
      displayName = "VLC";
      enable = true;
      package = pkgs.vlc-bin;

      link = true;
      appName = "VLC.app";
    };
  };


  # ------------------------------------------------------------
  # ------ ENABLED PACKAGES ------ #
  # ------------------------------------------------------------

  enabledDarwinMediaPackages = map (application: application.package) (
    lib.filter
      (application: application.enable or false)
      (lib.attrValues darwinMediaApplications)
  );


  # ------------------------------------------------------------
  # ------ APPLICATION LINK HELPER ------ #
  # Load the shared Darwin application-link helper
  # ------------------------------------------------------------

  applicationLinkHelper = import ./helper.nix {
    inherit lib pkgs;
  };


  # ------------------------------------------------------------
  # ------ MEDIA APPLICATION LINKS ------ #
  # Configure link management for this package group
  # ------------------------------------------------------------

  darwinMediaApplicationLinks = applicationLinkHelper {
    applications = darwinMediaApplications;

    sourceDirectory = mediaApplicationSourceDirectory;

    targetDirectory = mediaApplicationTargetDirectory;

    managerName = mediaLinkManagerName;
  };
in
{
  # ------------------------------------------------------------
  # ------ DARWIN MEDIA PACKAGES ------ #
  # Install all enabled packages
  # ------------------------------------------------------------

  environment.systemPackages = enabledDarwinMediaPackages;


  # ------------------------------------------------------------
  # ------ DARWIN MEDIA LINKS ------ #
  # Run categorized application-link management after activation
  # ------------------------------------------------------------

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${darwinMediaApplicationLinks.linkManager}/bin/${mediaLinkManagerName}
  '';
}