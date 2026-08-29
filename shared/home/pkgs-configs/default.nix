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

{
  # ------------------------------------------------------------
  # ------ SHARED FEATURE MODULE INPUTS ------ #
  # Paths are wired once at this shared Home Manager boundary.

  imports =
    let
      paths = import ../../../options/paths.nix { };
    in
    [
      # Espanso feature definitions
      ../../../options/pkgs-configs/espanso/default.nix

      # Shared Espanso toggle selection and base/default configuration files
      (import ./espanso { inherit paths; })
    ];
}
