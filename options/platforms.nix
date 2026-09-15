# options/platforms.nix
#
# =====================================================================
# OPTIONS: PLATFORM DETECTION
#
# Provides the shared platform checks used by package-list modules.
# =====================================================================

{ pkgs }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM CHECKS ------ #
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ PACKAGE PLATFORM FILTERING ------ #
  # ------------------------------------------------------------

  enabledForCurrentPlatform = package:
    (package.enable or false)
    && (
      (isDarwin && (package.installOn.darwin or false))
      || (isLinux && (package.installOn.linux or false))
    );

  # ------------------------------------------------------------
  # ------ PLATFORM VALUE SELECTION ------ #
  # Resolves a Darwin or Linux value from a shared per-platform
  # attribute set, such as an alias path declared in paths.nix.
  # ------------------------------------------------------------

  valueForCurrentPlatform = values:
    if isDarwin then
      values.darwin or null
    else if isLinux then
      values.linux or null
    else
      null;

  # ------------------------------------------------------------
  # ------ PLATFORM-ONLY ATTRIBUTES ------ #
  # Drops the attributes entirely on other platforms. Needed for option
  # paths that exist in only one module system (services.*, systemd, and
  # networking.firewall on NixOS), where a false lib.mkIf still defines
  # the path, and for flake outputs that only evaluate on one platform.
  # ------------------------------------------------------------

  onlyOnLinux = definitions: if isLinux then definitions else { };
  onlyOnDarwin = definitions: if isDarwin then definitions else { };
in
{
  inherit
    isDarwin
    isLinux
    enabledForCurrentPlatform
    valueForCurrentPlatform
    onlyOnLinux
    onlyOnDarwin
    ;
}
