# darwin/packages/tools-pkgs.nix
#
# =====================================================================
# PACKAGES: DARWIN TOOLS
#
# Declares macOS-only utility applications. Common helpers install the
# selected entries and manage their guarded /Applications/Tools links.
# =====================================================================

{ packageOptions, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ TOOL PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  toolPackages = {
    # ---- A Better Finder Attributes
    # Changes Finder metadata, timestamps, labels, and photo attributes.
    betterFinderAttributes = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./better-finder-attributes.nix { };
      appName = "A Better Finder Attributes 7.app";
      symlinkTools = true;
    };

    # ---- A Better Finder Rename
    # Provides advanced batch file and folder renaming.
    betterFinderRename = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./better-finder-rename.nix { };
      appName = "A Better Finder Rename 12.app";
      symlinkTools = true;
    };

    # ---- AssetSnap
    # Provides developer assets from the macOS menu bar.
    assetsnap = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./assetsnap.nix { };
      appName = "AssetSnap.app";
      symlinkTools = true;
    };

    # ---- Floe
    # Hides and reveals menu bar applications using native macOS controls.
    floe = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./floe.nix { };
      appName = "Floe.app";
      symlinkTools = true;
    };

    # ---- Hammerspoon
    # Automates macOS using Lua scripts and native system APIs.
    hammerspoon = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./hammerspoon.nix { };
      extraPackages = [
        # Keeps Hammerspoon's separate updater application installed.
        (pkgs.callPackage ./hammerspoon-update.nix { })
      ];
      appName = "Hammerspoon.app";
      symlinkTools = true;
    };

    # ---- The Unarchiver
    # Extracts ZIP, RAR, 7z, TAR, and other archive formats.
    theUnarchiver = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./unarchiver { };
      extraPackages = [
        # Keeps The Unarchiver's separate updater application installed.
        (pkgs.callPackage ./unarchiver/unarchiver-update.nix { })
      ];
      appName = "The Unarchiver.app";
      symlinkTools = true;
    };
  };
in
packageOptions.mkPackageModule {
  name = "darwin-tools";
  packages = toolPackages;
}
