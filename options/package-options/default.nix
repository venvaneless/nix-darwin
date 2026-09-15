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
  paths,
  platforms,
  pkgs,
  installTarget ? null,
  ...
}@args:

let
  # ------------------------------------------------------------
  # ------ SHARED OPTION HELPERS ------ #
  # ------------------------------------------------------------

  symlinks = import ../symlinks.nix { inherit lib paths pkgs; };

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

  symlinkFlags = [
    "symlinkApplications"
    "symlinkProgramming"
    "symlinkProductivity"
    "symlinkTools"
    "symlinkMultimedia"
    "symlinkSystem"
  ];

  # The option-module branch is imported only by nix-darwin and therefore
  # always installs into the system package set. Other consumers supply
  # their install target through the plain helper branch.
  packageInstallTarget = if args ? config then "system" else installTarget;

  # ------------------------------------------------------------
  # ------ PACKAGE MODULE FACTORY ------ #
  # Kept in the shared scope so the plain helper and Darwin option module
  # install packages through the same filtering and linking behavior.
  # ------------------------------------------------------------

  mkPackageModule = { name, packages }:
    let
      normalizedPackages = normalizePackages packages;
      installedPackages = selectedPackages normalizedPackages;
      hasApplications = lib.any (package: package ? appName) (lib.attrValues normalizedPackages);
      invalidLinkEntries = lib.filter
        (package:
          lib.any (flag: package.${flag} or false) symlinkFlags
          && !(package ? appName))
        (lib.attrValues normalizedPackages);
      applicationLinkManager = symlinks.mkApplicationLinkManager {
        inherit name;
        packages = normalizedPackages;
      };

      packageConfig =
        if packageInstallTarget == "system" then
          { environment.systemPackages = installedPackages; }
        else if packageInstallTarget == "home" then
          { home.packages = installedPackages; }
        else
          throw "${name}: installTarget must be system or home";
    in
    if invalidLinkEntries != [ ] then
      throw "${name}: every Darwin symlink flag requires appName"
    else
      lib.mkMerge [
        packageConfig

        (if packageInstallTarget == "system" then
          lib.mkIf (platforms.isDarwin && hasApplications) {
            # Link bundles before Dock defaults resolve persistent apps.
            system.activationScripts.applications.text = lib.mkAfter ''
              ${applicationLinkManager}/bin/manage-${name}-application-links
            '';
          }
        else
          { })
      ];
in
if !(args ? config) then {
  # ------------------------------------------------------------
  # ------ PACKAGE MODULE FACTORY ------ #
  # ------------------------------------------------------------

  inherit darwinPackages enabledForCurrentPlatform mkPackageModule selectedPackages;
}
else
let
  cfg = config.system.packages.darwin;

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION ASSEMBLY ------ #
  # darwin/packages/default.nix supplies each package and application
  # bundle name. This module only applies the shared installation and
  # guarded-link semantics to those selected Darwin values.
  # ------------------------------------------------------------

  iterm2Plugins = {
    # Optional iTerm2 AI integration bundle.
    itermAiPlugin = cfg.iterm2.plugins.ai;

    # Optional iTerm2 embedded-browser bundle.
    itermBrowserPlugin = cfg.iterm2.plugins.browser;
  };

  darwinApplications =
    lib.mapAttrs
      (_: application: application // {
        # Darwin-only package definitions never expose a Linux selection.
        installOn.darwin = true;
      })
      ({
        # Terminal emulator and its optional integration bundles.
        iterm2 = builtins.removeAttrs cfg.iterm2 [ "plugins" ];

        # Finder metadata editing application.
        betterFinderAttributes = cfg.betterFinderAttributes;

        # Finder batch-renaming application.
        betterFinderRename = cfg.betterFinderRename;

        # Menu-bar application visibility utility.
        floe = cfg.floe;

        # macOS automation application and its source updater.
        hammerspoon = cfg.hammerspoon;

        # Developer asset manager application.
        assetsnap = cfg.assetsnap;

        # Archive extraction application from the pinned stable package set.
        theUnarchiver = cfg.theUnarchiver;
      } // iterm2Plugins);

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

  options.system.packages.darwin = lib.mkOption {
    type = lib.types.submodule {
      options = {
        iterm2 = lib.mkOption {
          type = lib.types.submodule {
            options = (darwinApplicationSettings "iTerm2") // {
              plugins = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    ai = darwinApplicationOption "the iTerm2 AI plugin";
                    browser = darwinApplicationOption "the iTerm2 browser plugin";
                  };
                };
                default = { };
                description = "Darwin package configuration for optional iTerm2 plugins.";
              };
            };
          };
          default = { };
          description = "Darwin package configuration for iTerm2 and its plugins.";
        };
        betterFinderAttributes = darwinApplicationOption "A Better Finder Attributes";
        betterFinderRename = darwinApplicationOption "A Better Finder Rename";
        floe = darwinApplicationOption "Floe";
        hammerspoon = darwinApplicationOption "Hammerspoon";
        assetsnap = darwinApplicationOption "AssetSnap";
        theUnarchiver = darwinApplicationOption "The Unarchiver";
      };
    };
    default = { };
    description = "Darwin-only Nix application package configuration.";
  };

  # Installs the enabled Darwin applications and delegates guarded links
  # to the existing options/symlinks.nix implementation.
  config = mkPackageModule {
    name = "darwin-applications";
    packages = darwinApplications;
  };
}
