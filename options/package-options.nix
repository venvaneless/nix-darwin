# options/package-options.nix
#
# =====================================================================
# OPTIONS: PACKAGE MODULE HELPERS
#
# Installs declarative package lists on the active platform and attaches
# the shared Darwin application-link manager when entries request it.
# This is a pure helper: it never reads the Nix module configuration.
# =====================================================================

{
  lib,
  paths,
  platforms,
  pkgs,
  installTarget,
}:

let
  # ------------------------------------------------------------
  # ------ SHARED OPTION HELPERS ------ #
  # ------------------------------------------------------------

  symlinks = import ./symlinks.nix { inherit lib paths pkgs; };

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
in
{
  # ------------------------------------------------------------
  # ------ PACKAGE MODULE FACTORY ------ #
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
        if installTarget == "system" then
          { environment.systemPackages = installedPackages; }
        else if installTarget == "home" then
          { home.packages = installedPackages; }
        else
          throw "${name}: installTarget must be system or home";
    in
    if invalidLinkEntries != [ ] then
      throw "${name}: every Darwin symlink flag requires appName"
    else
      lib.mkMerge [
        packageConfig

        (if installTarget == "system" then
          lib.mkIf (platforms.isDarwin && hasApplications) {
            # Link bundles before Dock defaults resolve persistent apps.
            system.activationScripts.applications.text = lib.mkAfter ''
              ${applicationLinkManager}/bin/manage-${name}-application-links
            '';
          }
        else
          { })
      ];

  inherit enabledForCurrentPlatform selectedPackages;
}
