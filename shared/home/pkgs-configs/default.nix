# shared/home/pkgs-configs/default.nix
#
# =====================================================================
# HOME PACKAGE CONFIGURATIONS
#
# Imports Home Manager configuration for applications and tools whose
# packages are installed elsewhere by the shared package registry.
#
# Package installation remains in shared/packages.nix so the existing
# enable, installOn, and Darwin application-link helpers continue to
# control where each package is installed.
#
# Files below this directory own user configuration under $HOME.
# =====================================================================

{ lib, pkgs, ... }:

let
  paths = import ../../../options/paths.nix;

  espanso = import ./espanso/default.nix {
    inherit lib paths pkgs;
  };
in
{
  imports = [
    espanso.homeModule
  ];
}