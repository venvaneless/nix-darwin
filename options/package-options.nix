# options/package-options.nix
#
# =====================================================================
# OPTIONS: PACKAGE MODULE HELPERS
#
# Installs declarative package lists on the active platform and attaches
# the shared Darwin application-link manager when entries request it.
# =====================================================================

{ lib, options, platforms, symlinks }:

let
  # ------------------------------------------------------------
  # ------ PACKAGE DESTINATION ------ #
  # ------------------------------------------------------------

  hasSystemPackages = lib.hasAttrByPath [ "environment" "systemPackages" ] options;
  hasHomePackages = lib.hasAttrByPath [ "home" "packages" ] options;

  # ------------------------------------------------------------
  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  # ------------------------------------------------------------

  enabledForCurrentPlatform = package:
    (package.enable or false)
    && (
      (platforms.isDarwin && (package.installOn.darwin or false))
      || (platforms.isLinux && (package.installOn.linux or false))
    );

  selectedPackages = packages:
    lib.concatMap
      (package: [ package.package ] ++ (package.extraPackages or [ ]))
      (lib.filter enabledForCurrentPlatform (lib.attrValues packages));

  # ------------------------------------------------------------
  # ------ PLATFORM PACKAGE SELECTION ------ #
  # ------------------------------------------------------------

  byPlatform = {
    darwin ? null,
    linux ? null,
  }:
    if platforms.isDarwin && darwin != null then
      darwin
    else if platforms.isLinux && linux != null then
      linux
    else
      throw "This package has no definition for the current platform";

  symlinkFlags = [
    "symlinkApplications"
    "symlinkProgramming"
    "symlinkProductivity"
    "symlinkTools"
    "symlinkMultimedia"
    "symlinkSystem"
  ];
in
{
  # ------------------------------------------------------------
  # ------ PACKAGE MODULE FACTORY ------ #
  # ------------------------------------------------------------

  mkPackageModule = { name, packages }:
    let
      installedPackages = selectedPackages packages;
      hasApplications = lib.any (package: package ? appName) (lib.attrValues packages);
      invalidLinkEntries = lib.filter
        (package:
          lib.any (flag: package.${flag} or false) symlinkFlags
          && !(package ? appName))
        (lib.attrValues packages);
      applicationLinkManager = symlinks.mkApplicationLinkManager {
        inherit name packages;
      };

      packageConfig =
        if hasSystemPackages then
          { environment.systemPackages = installedPackages; }
        else if hasHomePackages then
          { home.packages = installedPackages; }
        else
          throw "${name}: this package module requires environment.systemPackages or home.packages";
    in
    if invalidLinkEntries != [] then
      throw "${name}: every Darwin symlink flag requires appName"
    else
      lib.mkMerge [
      packageConfig

      (if hasSystemPackages then
        lib.mkIf (platforms.isDarwin && hasApplications) {
          # Link bundles before Dock defaults resolve persistent apps.
          system.activationScripts.applications.text = lib.mkAfter ''
            ${applicationLinkManager}/bin/manage-${name}-application-links
          '';
        }
      else
        { })
      ];

  inherit byPlatform enabledForCurrentPlatform selectedPackages;
}
