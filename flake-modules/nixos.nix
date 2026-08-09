# flake-modules/nixos.nix
#
# =====================================================================
# NIXOS HOST: 2015 INTEL MAC
#
# Exports the reusable NixOS host module while deliberately leaving the
# target-generated hardware configuration outside this repository.
# =====================================================================

{ inputs, ... }:

{
  # ---- REUSABLE NIXOS HOST MODULE ---- #
  # Add this with a target-generated nixos/hardware-configuration.nix to a
  # future mkNixosHost call before exposing nixosConfigurations.ven. Pass the
  # flake input set as extraSpecialArgs.inputs for shared host policy; the
  # integrated Home Manager module does not require inputs.self.
  flake.nixosModules.ven = {
    imports = [
      # Provides the integrated Home Manager NixOS module.
      inputs.home-manager.nixosModules.home-manager

      # Provides the supplied system and user configuration.
      ../nixos/default.nix
      ../nixos/home-manager.nix
    ];
  };
}
