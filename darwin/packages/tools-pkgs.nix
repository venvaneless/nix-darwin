# darwin/packages/tools-pkgs.nix
#
# =====================================================================
# PACKAGES: DARWIN TOOLS
#
# Installs macOS-only utility applications:
# - Menu bar utilities
# - General-purpose tools
# - Developer-adjacent utilities
# =====================================================================

{ lib, pkgs, venPackages, ... }:

let
  # ------------------------------------------------------------
  # ------ TOOL PACKAGE SETTINGS ------ #
  # Important package-group paths and behavior
  # ------------------------------------------------------------

  toolApplicationSourceDirectory = "/Applications/Nix Apps";

  toolApplicationTargetDirectory = "/Applications/Tools";

  toolLinkManagerName = "manage-darwin-tool-application-links";

  # ------------------------------------------------------------
  # ------ CUSTOM PACKAGES ------ #
  # ------------------------------------------------------------

  assetsnapPackage = venPackages.assetsnap;

  betterFinderAttributesPackage = venPackages.better-finder-attributes;

  betterFinderRenamePackage = venPackages.better-finder-rename;

  hammerspoonPackage = venPackages.hammerspoon;

  hammerspoonUpdater = venPackages.update-hammerspoon;

  theUnarchiverPackage = venPackages.the-unarchiver;

  theUnarchiverUpdater = venPackages.update-unarchiver;

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

    # ---- The Unarchiver
    # Extracts ZIP, RAR, 7z, TAR, and other archive formats.
    theUnarchiver = {
      displayName = "The Unarchiver";
      enable = true;
      package = theUnarchiverPackage;

      link = true;
      appName = "The Unarchiver.app";
    };
  };

  # ------------------------------------------------------------
  # ------ ENABLED PACKAGES ------ #
  # ------------------------------------------------------------

  enabledToolPackages = map (application: application.package) (
    lib.filter (application: application.enable or false) (lib.attrValues toolApplications)
  );

  # ------------------------------------------------------------
  # ------ APPLICATION LINK HELPER ------ #
  # Load the shared Darwin application-link helper
  # ------------------------------------------------------------

  applicationLinkHelper = import ./helper.nix {
    inherit lib pkgs;
  };

  # ------------------------------------------------------------
  # ------ TOOL APPLICATION LINKS ------ #
  # Configure link management for this package group
  # ------------------------------------------------------------

  toolApplicationLinks = applicationLinkHelper {
    applications = toolApplications;

    sourceDirectory = toolApplicationSourceDirectory;

    targetDirectory = toolApplicationTargetDirectory;

    managerName = toolLinkManagerName;
  };
in
{
  # ------------------------------------------------------------
  # ------ DARWIN TOOL PACKAGES ------ #
  # Install all enabled packages
  # ------------------------------------------------------------

  environment.systemPackages =
  enabledToolPackages
  ++ [
    hammerspoonUpdater
    theUnarchiverUpdater
  ];

  # ------------------------------------------------------------
  # ------ DARWIN TOOL LINKS ------ #
  # Run categorized application-link management after activation
  # ------------------------------------------------------------

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${toolApplicationLinks.linkManager}/bin/${toolLinkManagerName}
  '';
}
