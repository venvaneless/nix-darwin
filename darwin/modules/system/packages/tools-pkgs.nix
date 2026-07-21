# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/tools-pkgs.nix
#
# =====================================================================
# PACKAGES: DARWIN TOOLS
#
# Installs macOS-only utility applications:
# - Menu bar utilities
# - General-purpose tools
# - Developer-adjacent utilities
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ TOOL PACKAGE SETTINGS ------ #
  # Important package-group paths and behavior
  # ------------------------------------------------------------

  toolApplicationSourceDirectory =
    "/Applications/Nix Apps";

  toolApplicationTargetDirectory =
    "/Applications/Tools";

  toolLinkManagerName =
    "manage-darwin-tool-application-links";


  # ------------------------------------------------------------
  # ------ CUSTOM PACKAGES ------ #
  # ------------------------------------------------------------

  assetsnapPackage =
    pkgs.callPackage ./assetsnap.nix { };

  betterFinderAttributesPackage =
    pkgs.callPackage ./better-finder-attributes.nix { };

  betterFinderRenamePackage =
    pkgs.callPackage ./better-finder-rename.nix { };

  hammerspoonPackage =
    pkgs.callPackage ./hammerspoon.nix { };


  # ------------------------------------------------------------
  # ------ TOOL DEFINITIONS ------ #
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
  # Non-GUI packages can omit link and appName.
  # ------------------------------------------------------------

  toolApplications = {
    # ---- A Better Finder Attributes
    # Changes Finder metadata, timestamps, labels, and photo attributes.
    betterFinderAttributes = {
      displayName = "A Better Finder Attributes";
      enable = true;
      package = betterFinderAttributesPackage;

      link = true;
      appName = "A Better Finder Attributes 7.app";
    };

    # ---- A Better Finder Rename
    # Provides advanced batch file and folder renaming.
    betterFinderRename = {
      displayName = "A Better Finder Rename";
      enable = true;
      package = betterFinderRenamePackage;

      link = true;
      appName = "A Better Finder Rename 12.app";
    };

    # ---- AssetSnap
    # Provides developer assets from the macOS menu bar.
    assetsnap = {
      displayName = "AssetSnap";
      enable = true;
      package = assetsnapPackage;

      link = true;
      appName = "AssetSnap.app";
    };

    # ---- Hammerspoon
    # Automates macOS using Lua scripts and native system APIs.
    hammerspoon = {
      displayName = "Hammerspoon";
      enable = true;
      package = hammerspoonPackage;

      link = true;
      appName = "Hammerspoon.app";
    };
  };


  # ------------------------------------------------------------
  # ------ ENABLED PACKAGES ------ #
  # ------------------------------------------------------------

  enabledToolPackages =
    map
      (application:
        application.package
      )
      (
        lib.filter
          (application:
            application.enable or false
          )
          (lib.attrValues toolApplications)
      );


  # ------------------------------------------------------------
  # ------ APPLICATION LINK HELPER ------ #
  # Load the shared Darwin application-link helper
  # ------------------------------------------------------------

  applicationLinkHelper =
    import ./helper.nix {
      inherit lib pkgs;
    };


  # ------------------------------------------------------------
  # ------ TOOL APPLICATION LINKS ------ #
  # Configure link management for this package group
  # ------------------------------------------------------------

  toolApplicationLinks =
    applicationLinkHelper {
      applications =
        toolApplications;

      sourceDirectory =
        toolApplicationSourceDirectory;

      targetDirectory =
        toolApplicationTargetDirectory;

      managerName =
        toolLinkManagerName;
    };
in
{
  # ------------------------------------------------------------
  # ------ DARWIN TOOL PACKAGES ------ #
  # Install all enabled packages
  # ------------------------------------------------------------

  environment.systemPackages =
    enabledToolPackages;


  # ------------------------------------------------------------
  # ------ DARWIN TOOL LINKS ------ #
  # Run categorized application-link management after activation
  # ------------------------------------------------------------

  system.activationScripts.postActivation.text =
    lib.mkAfter ''
      ${toolApplicationLinks.linkManager}/bin/${toolLinkManagerName}
    '';
}