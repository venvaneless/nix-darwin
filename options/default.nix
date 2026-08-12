# options/default.nix
#
# =====================================================================
# OPTIONS: PACKAGE HELPER IMPORT
#
# Provides the small shared helpers used by category package modules.
# It does not collect package declarations or create a global registry.
# =====================================================================

{ lib, pkgs, ... }:

let
  paths = import ./paths.nix { };
  platforms = import ./platforms.nix { inherit pkgs; };
  symlinks = import ./symlinks.nix { inherit lib paths pkgs; };
  packageOptions = import ./package-options.nix {
    inherit lib platforms symlinks;
  };
in
{
  inherit paths platforms symlinks packageOptions;
}
