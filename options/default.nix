# options/default.nix
#
# =====================================================================
# OPTIONS: SHARED SETTINGS AND HELPERS
#
# Cross-machine settings that are not package declarations. Every value
# here is written once and read by every machine that needs it.
#
# Read whichever values a caller needs, supplying only the arguments
# those values require:
#
#   (import ../options { }).nixpkgsConfig
#   (import ../options { inherit inputs pkgs; }).unstablePkgs
#
# Every argument defaults to null, and Nix is lazy, so a value is only
# built when something actually reads it.
# =====================================================================

{
  inputs ? null,
  lib ? null,
  options ? null,
  pkgs ? null,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ SHARED NIXPKGS POLICY ------ #
  #
  # Applied to every nixpkgs instance on every machine, stable and
  # unstable alike.
  # ------------------------------------------------------------

  nixpkgsConfig = {
    allowUnfree = true;

    permittedInsecurePackages = [
    ];
  };

  # ------------------------------------------------------------
  # ------ UNSTABLE PACKAGE SET ------ #
  #
  # Built for the current system under the same policy as the stable
  # set. Read it in any module that needs an unstable package:
  #
  #   helpers = import ../options { inherit inputs lib options pkgs; };
  #   inherit (helpers) unstablePkgs;
  # ------------------------------------------------------------

  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = nixpkgsConfig;
  };

  paths = import ./paths.nix { };

  # ------------------------------------------------------------
  # ------ SERVICE OPTION MODULE ------ #
  #
  # Keeps the service option tree discoverable through the same helper
  # interface without turning this helper file into a Nix module itself.
  # ------------------------------------------------------------

  serviceOptions = ./services/default.nix;
in
{
  inherit
    nixpkgsConfig
    unstablePkgs
    paths
    serviceOptions
    ;
}
