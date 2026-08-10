# shared/packages/productivity-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED PRODUCTIVITY TOOLS
#
# Installs communication and productivity packages shared between
# Darwin and Linux:
# - Vesktop, an alternate Discord client with Vencord built in
# - Signal Desktop messenger
# - Signal chat export tool
#
# Each package provides:
# - A global enable or disable toggle
# - A Darwin installation toggle
# - A Linux installation toggle
# - An optional categorized Darwin application link
#
# Darwin installs the application bundles into /Applications/Nix Apps.
# The shared link helper then links them into:
# /Applications/Productivity
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
  # ------ PRODUCTIVITY PACKAGE SETTINGS ------ #
  # Important package-group paths and behavior
  # ------------------------------------------------------------

  productivityApplicationSourceDirectory = "/Applications/Nix Apps";

  productivityApplicationTargetDirectory = "/Applications/Productivity";

  productivityLinkManagerName = "manage-shared-productivity-application-links";


  # ------------------------------------------------------------
  # ------ SHARED PRODUCTIVITY PACKAGE DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the package exists at all.
  #
  # installOn.darwin:
  #   Controls whether the package is installed on macOS.
  #
  # installOn.linux:
  #   Controls whether the package is installed on Linux.
  #
  # darwinLink:
  #   Optionally links the application bundle from
  #   /Applications/Nix Apps into the categorized directory above.
  #   Entries without darwinLink are treated as non-GUI packages.
  # ------------------------------------------------------------

  productivityPackages = {
    # ---- Vesktop
    # Alternate Discord client with Vencord built in.
    # Replaces the former Homebrew cask on macOS.
    vesktop = {
      displayName = "Vesktop";
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.vesktop;

      darwinLink = {
        enable = true;
        appName = "Vesktop.app";
      };
    };

    # ---- Signal Desktop
    # Private messenger linked to the Signal mobile application.
    signalDesktop = {
      displayName = "Signal";
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.signal-desktop;

      darwinLink = {
        enable = true;
        appName = "Signal.app";
      };
    };

    # ---- Signal Export
    # Command-line tool that exports Signal chats to Markdown.
    # Provides `sigexport` and has no application bundle.
    signalExport = {
      displayName = "Signal Export";
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.signal-export;
    };
  };


  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  #
  # Selects only packages that are enabled for the system that
  # is currently evaluating this module.
  # ------------------------------------------------------------

  enabledForCurrentSystem =
    productivityPackage:
      productivityPackage.enable
      && (
        (isDarwin && productivityPackage.installOn.darwin)
        || (isLinux && productivityPackage.installOn.linux)
      );

  enabledProductivityPackages = map
    (productivityPackage: productivityPackage.package)
    (lib.filter enabledForCurrentSystem (lib.attrValues productivityPackages));


  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINK DEFINITIONS ------ #
  #
  # Translates the shared package definitions into the shape the
  # link helper expects.
  #
  # Disabled applications stay in the list on purpose, so that a
  # previously created link is removed instead of being orphaned.
  # ------------------------------------------------------------

  managedDarwinApplications =
    lib.mapAttrs
      (_: productivityPackage: {
        displayName = productivityPackage.displayName;

        appName = productivityPackage.darwinLink.appName;

        # The bundle is only expected when the package is installed
        # on macOS at all.
        enable =
          productivityPackage.enable
          && productivityPackage.installOn.darwin;

        # The categorized link can be disabled independently.
        link = productivityPackage.darwinLink.enable;
      })
      (
        lib.filterAttrs
          (_: productivityPackage: productivityPackage ? darwinLink)
          productivityPackages
      );


  # ------------------------------------------------------------
  # ------ APPLICATION LINK HELPER ------ #
  # Load the shared Darwin application-link helper
  # ------------------------------------------------------------

  applicationLinkHelper = import ../../darwin/packages/helper.nix {
    inherit lib pkgs;
  };


  # ------------------------------------------------------------
  # ------ PRODUCTIVITY APPLICATION LINKS ------ #
  # Configure link management for this package group
  # ------------------------------------------------------------

  productivityApplicationLinks = applicationLinkHelper {
    applications = managedDarwinApplications;

    sourceDirectory = productivityApplicationSourceDirectory;

    targetDirectory = productivityApplicationTargetDirectory;

    managerName = productivityLinkManagerName;
  };
in
{
  config = lib.mkMerge [
    {
      # ------------------------------------------------------------
      # ------ SHARED PRODUCTIVITY PACKAGES ------ #
      #
      # Installs the filtered productivity package set for the
      # current Darwin or Linux system.
      # ------------------------------------------------------------

      environment.systemPackages = enabledProductivityPackages;
    }

    # ------------------------------------------------------------
    # ------ DARWIN APPLICATION LINK ACTIVATION ------ #
    #
    # Runs only on Darwin and after nix-darwin has populated
    # /Applications/Nix Apps.
    # ------------------------------------------------------------

    (lib.mkIf isDarwin {
      system.activationScripts.postActivation.text = lib.mkAfter ''
        ${productivityApplicationLinks.linkManager}/bin/${productivityLinkManagerName}
      '';
    })
  ];
}
