# shared/hosts.nix
#
# =====================================================================
# SHARED HOST CONFIGURATION
#
# Configuration shared by Darwin and Linux hosts:
# - Stable nixpkgs package policy
# - Unstable nixpkgs package set
# =====================================================================

{ inputs, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED NIXPKGS CONFIGURATION ------ #
  #
  # Used by both the stable and unstable package sets.
  # ------------------------------------------------------------

  sharedNixpkgsConfig = {
    allowUnfree = true;

    permittedInsecurePackages = [
    ];
  };
in
{
  # ------------------------------------------------------------
  # ------ STABLE PACKAGE SET ------ #
  # ------------------------------------------------------------

  nixpkgs.config =
    sharedNixpkgsConfig;

  # ------------------------------------------------------------
  # ------ UNSTABLE PACKAGE SET ------ #
  #
  # Makes unstablePkgs available to other imported modules as:
  #
  # { unstablePkgs, ... }:
  # ------------------------------------------------------------

  _module.args.unstablePkgs =
    import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.hostPlatform.system;
      config = sharedNixpkgsConfig;
    };
}
