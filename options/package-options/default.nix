# options/package-options/default.nix
#
# =====================================================================
# OPTIONS: PACKAGE MODULE HELPERS
#
# Installs declarative package lists on the active platform and attaches
# the shared Darwin application-link manager when entries request it.
# Its module branch declares the Darwin-only application configuration
# interface consumed by darwin/packages/default.nix.
# =====================================================================

{
  config ? null,
  lib,
  packageOptionsMode,
  paths,
  platforms,
  pkgs,
  symlinks ? null,
  installTarget ? null,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ SHARED OPTION HELPERS ------ #
  # ------------------------------------------------------------

  # ------------------------------------------------------------
  # ------ DARWIN PACKAGE VALUES ------ #
  # Applies each custom package definition once. Host composition passes
  # these values into Darwin modules instead of making machine settings
  # import or call package definitions themselves.
  # ------------------------------------------------------------

  hammerspoonPackages = pkgs.callPackage ./hammerspoon.nix { inherit paths; };

  darwinPackages = {
    assetsnap = pkgs.callPackage ./assetsnap.nix { };
    betterFinderAttributes = pkgs.callPackage ./better-finder-attributes.nix { };
    betterFinderRename = pkgs.callPackage ./better-finder-rename.nix { };
    floe = pkgs.callPackage ./floe.nix { };
    hammerspoon = hammerspoonPackages.hammerspoon;
    updateHammerspoon = hammerspoonPackages.updateHammerspoon;
    itermAiPlugin = pkgs.callPackage ./iterm-ai-plugin.nix { };
    itermBrowserPlugin = pkgs.callPackage ./iterm-browser-plugin.nix { };
  };

  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  # Platform eligibility is defined once in options/platforms.nix.
  # ------------------------------------------------------------

  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform;

  selectedPackages = packages:
    lib.concatMap
      (package: [ package.package ] ++ (package.extraPackages or [ ]))
      (lib.filter enabledForCurrentPlatform (lib.attrValues packages));

  # ------------------------------------------------------------
  # ------ PLATFORM PACKAGE SELECTION ------ #
  # ------------------------------------------------------------

  selectPackage = name: package:
    if package ? package then
      package.package
    else if !(package ? packageByPlatform) then
      throw "${name}: package or packageByPlatform must be set"
    else if platforms.isDarwin && (package.packageByPlatform.darwin or null) != null then
      package.packageByPlatform.darwin
    else if platforms.isLinux && (package.packageByPlatform.linux or null) != null then
      package.packageByPlatform.linux
    else
      throw "${name}: packageByPlatform has no package for the current platform";

  normalizeEntry = name: package:
    lib.filterAttrs (_: value: value != null) (package // {
      package = selectPackage name package;
      packageByPlatform = null;
    });

  normalizePackages = packages:
    lib.mapAttrs normalizeEntry packages;

  applicationLinkEntries = packages:
    lib.mapAttrs
      (_: package: builtins.removeAttrs package [ "package" "extraPackages" "installOn" ])
      (lib.filterAttrs (_: package: package ? appName) packages);

  # The caller explicitly selects module or helper use before Nix resolves
  # module arguments. This avoids looking up config or installTarget through
  # _module.args while the module graph is still being constructed.
  packageInstallTarget = if packageOptionsMode then "system" else installTarget;

  # ------------------------------------------------------------
  # ------ PACKAGE MODULE FACTORY ------ #
  # Kept in the shared scope so the plain helper and Darwin option module
  # install packages through the same filtering and linking behavior.
  # ------------------------------------------------------------

  mkPackageModule = { name, packages, symlinks ? null }:
    let
      normalizedPackages = normalizePackages packages;
      installedPackages = selectedPackages normalizedPackages;
      applicationLinks = applicationLinkEntries normalizedPackages;

      packageConfig =
        if packageInstallTarget == "system" then
          { environment.systemPackages = installedPackages; }
        else if packageInstallTarget == "home" then
          { home.packages = installedPackages; }
        else
          throw "${name}: installTarget must be system or home";
    in
    lib.mkMerge [
      packageConfig

      (if packageInstallTarget == "system" && platforms.isDarwin && applicationLinks != { } then
        # Package options attach the shared link manager using only
        # stripped link entries; symlinks.nix owns its implementation.
        if symlinks == null then
          throw "${name}: Darwin application links require the Darwin symlink helper"
        else
          symlinks.mkApplicationLinkModule {
            inherit name;
            applications = applicationLinks;
          }
      else
        { })
    ];
in
if !packageOptionsMode then {
  # ------------------------------------------------------------
  # ------ PACKAGE MODULE FACTORY ------ #
  # ------------------------------------------------------------

  inherit darwinPackages enabledForCurrentPlatform mkPackageModule selectedPackages;
}
else
let
  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION ASSEMBLY ------ #
  # darwin/packages/default.nix supplies each package and application
  # bundle name. This module only applies the shared installation and
  # guarded-link semantics to those selected Darwin values.
  # ------------------------------------------------------------

  iterm2Extensions = {
    # Optional iTerm2 AI integration bundle.
    itermAiPlugin = config.system.darwin.packages.iterm2.ai;

    # Optional iTerm2 embedded-browser bundle.
    itermBrowserPlugin = config.system.darwin.packages.iterm2.browser;
  };

  darwinApplications =
    lib.mapAttrs
      (_: application: application // {
        # Darwin-only package definitions never expose a Linux selection.
        installOn.darwin = true;
      })
      ({
        # Terminal emulator and its optional integration bundles.
        iterm2 = builtins.removeAttrs config.system.darwin.packages.iterm2 [ "ai" "browser" ];

        # Finder metadata editing application.
        betterFinderAttributes = config.system.darwin.packages.betterFinderAttributes;

        # Finder batch-renaming application.
        betterFinderRename = config.system.darwin.packages.betterFinderRename;

        # Menu-bar application visibility utility.
        floe = config.system.darwin.packages.floe;

        # macOS automation application and its source updater.
        hammerspoon = config.system.darwin.packages.hammerspoon;

        # Developer asset manager application.
        assetsnap = config.system.darwin.packages.assetsnap;

        # Archive extraction application from the pinned stable package set.
        theUnarchiver = config.system.darwin.packages.theUnarchiver;
      } // iterm2Extensions);

  # The Darwin package file supplies package metadata and user-selected
  # application settings. Link execution itself remains in symlinks.nix.
  darwinApplicationSettings = description: {
    package = lib.mkOption {
      type = lib.types.package;
      description = "Nix package installed for ${description}.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional Nix packages installed with ${description}.";
    };

    appName = lib.mkOption {
      type = lib.types.str;
      description = "Application bundle name managed for ${description}.";
    };

    enable = lib.mkEnableOption description;

    symlinkApplications = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Link ${description} into the main application category.";
    };

    symlinkProgramming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Link ${description} into the programming application category.";
    };

    symlinkProductivity = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Link ${description} into the productivity application category.";
    };

    symlinkTools = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Link ${description} into the tools application category.";
    };

    symlinkMultimedia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Link ${description} into the multimedia application category.";
    };

    symlinkSystem = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Link ${description} into the system application category.";
    };
  };

  darwinApplicationOption = description:
    lib.mkOption {
      type = lib.types.submodule {
        options = darwinApplicationSettings description;
      };
      default = { };
      description = "Darwin package configuration for ${description}.";
    };
in
{
  # ------------------------------------------------------------
  # ------ DARWIN PACKAGE CONFIGURATION INTERFACE ------ #
  # Only nix-darwin imports this module, so this namespace never appears
  # in the Linux or standalone Home Manager module graphs.
  # ------------------------------------------------------------

  options.system.darwin.packages = {
    iterm2 = lib.mkOption {
      type = lib.types.submodule {
        options = (darwinApplicationSettings "iTerm2") // {
          ai = darwinApplicationOption "the iTerm2 AI plugin";
          browser = darwinApplicationOption "the iTerm2 browser plugin";
        };
      };
      default = { };
      description = "Darwin package configuration for iTerm2 and its extensions.";
    };
    betterFinderAttributes = darwinApplicationOption "A Better Finder Attributes";
    betterFinderRename = darwinApplicationOption "A Better Finder Rename";
    floe = darwinApplicationOption "Floe";
    hammerspoon = darwinApplicationOption "Hammerspoon";
    assetsnap = darwinApplicationOption "AssetSnap";
    theUnarchiver = darwinApplicationOption "The Unarchiver";
  };

  # Installs the enabled Darwin applications and delegates guarded links
  # to the existing options/symlinks.nix implementation.
  config = mkPackageModule {
    name = "darwin-applications";
    packages = darwinApplications;
    inherit symlinks;
  };
}
