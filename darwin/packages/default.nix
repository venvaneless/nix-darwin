# darwin/packages/default.nix
#
# =====================================================================
# PACKAGES: DARWIN APPLICATION KNOBS
#
# Selects Darwin-only Nix application packages and their movable settings.
# Shared installation semantics and guarded application links live in
# options/package-options/default.nix and options/symlinks.nix.
# =====================================================================

{ darwinPackages, pkgs, unstablePkgs, ... }:

{
  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION SETTINGS ------ #
  # Enable packages and choose their guarded /Applications category.
  # ------------------------------------------------------------

  system.packages.darwin = {
    # Terminal emulator and its optional integration bundles.
    iterm2 = {
      enable = true;
      symlinkProgramming = true;
      package = unstablePkgs.iterm2;
      appName = "iTerm.app";

      plugins = {
        ai = {
          enable = true;
          symlinkProgramming = true;
          package = darwinPackages.itermAiPlugin;
          appName = "iTermAI.app";
        };

        browser = {
          enable = true;
          symlinkProgramming = true;
          package = darwinPackages.itermBrowserPlugin;
          appName = "iTermBrowser.app";
        };
      };
    };

    # Finder utilities.
    betterFinderAttributes = {
      enable = true;
      symlinkTools = true;
      package = darwinPackages.betterFinderAttributes;
      appName = "A Better Finder Attributes 7.app";
    };

    betterFinderRename = {
      enable = true;
      symlinkTools = true;
      package = darwinPackages.betterFinderRename;
      appName = "A Better Finder Rename 12.app";
    };

    # macOS utility applications.
    floe = {
      enable = true;
      symlinkTools = true;
      package = darwinPackages.floe;
      appName = "Floe.app";
    };

    hammerspoon = {
      enable = true;
      symlinkTools = true;
      package = darwinPackages.hammerspoon;
      extraPackages = [ darwinPackages.updateHammerspoon ];
      appName = "Hammerspoon.app";
    };

    assetsnap = {
      enable = true;
      symlinkTools = true;
      package = darwinPackages.assetsnap;
      appName = "AssetSnap.app";
    };

    theUnarchiver = {
      enable = true;
      symlinkTools = true;
      package = pkgs.the-unarchiver;
      appName = "The Unarchiver.app";
    };
  };

  # ------------------------------------------------------------
  # ------ DARWIN PACKAGE MODULES ------ #
  # Agent-specific package configuration remains separate from the
  # application knobs above because it owns package configuration too.
  # ------------------------------------------------------------

  imports = [
    ./agents-pkgs.nix
  ];
}
