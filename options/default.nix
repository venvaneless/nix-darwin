# options/default.nix
#
# =====================================================================
# OPTIONS: SHARED SETTINGS AND HELPERS
#
# Cross-machine settings that are not package declarations. Every value
# here is written once and read by every machine that needs it.
#
# This shared options helper exposes repository-owned values for host
# construction to pass into modules as custom arguments. Paths remain defined
# in paths.nix; this file only re-exports that existing value.
#
# Feature modules receive those values through specialArgs or
# home-manager.extraSpecialArgs instead of evaluating this helper themselves.
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
  # set. The host passes it through specialArgs to modules that need it.
  # ------------------------------------------------------------

  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = nixpkgsConfig;
  };

  paths = import ./paths.nix { };

  # ------------------------------------------------------------
  # ------ HOME MANAGER OPTION MODULES ------ #
  #
  # Exposes option-module paths to host construction. The paths are then
  # passed to the Home Manager graph rather than imported by a feature.
  # ------------------------------------------------------------

  serviceOptions = ./services/default.nix;
  terminalOptions = ./terminal-aliases.nix;
  obsidianOptions = ./obsidian/default.nix;

  # ------------------------------------------------------------
  # ------ SYSTEM OPTION MODULES ------ #
  #
  # Exposes system-level option-module paths to host construction. Unlike
  # the Home Manager paths above, the constructors in
  # flake-modules/hosts.nix apply these to the system module graph of
  # every machine.
  # ------------------------------------------------------------

  nixOptions = ./nix-options.nix;

in
{
  inherit
    nixpkgsConfig
    unstablePkgs
    paths
    serviceOptions
    terminalOptions
    obsidianOptions
    nixOptions
    ;
}
