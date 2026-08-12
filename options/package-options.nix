# options/package-options.nix
#
# =====================================================================
# OPTIONS: PACKAGE MODULE HELPERS
#
# Installs declarative package lists on the active platform and attaches
# the shared Darwin application-link manager when entries request it.
# =====================================================================

{ lib, platforms, symlinks }:

let
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
      applicationLinkManager =
        if platforms.isDarwin && hasApplications then
          symlinks.mkApplicationLinkManager { inherit name packages; }
        else
          null;

      packageConfig = {
        environment.systemPackages = installedPackages;
      };
    in
    if invalidLinkEntries != [] then
      throw "${name}: every Darwin symlink flag requires appName"
    else
      lib.mkMerge [
      packageConfig

      (if applicationLinkManager != null then {
        # Application bundles are available before postActivation runs.
        system.activationScripts.postActivation.text = lib.mkAfter ''
          ${applicationLinkManager}/bin/manage-${name}-application-links
        '';
      } else { })
      ];

  inherit byPlatform enabledForCurrentPlatform selectedPackages;
}
