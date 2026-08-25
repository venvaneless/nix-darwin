# flake-modules/imac-nix.nix
#
# =====================================================================
# NIXOS HOST: 2015 INTEL IMAC
#
# Everything that would otherwise sit in flake.nix for this machine.
#
# The host module is always exported. The buildable configuration only
# appears once the machine's own hardware description exists at:
#
#   nixos/imac/hardware-configuration.nix
#
# That file cannot be written here. It holds disk UUIDs, the filesystem
# layout, and the boot loader for the physical machine, so it has to be
# generated on the iMac itself:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > nixos/imac/hardware-configuration.nix
#
# After committing it, this file exposes nixosConfigurations.imac and:
#
#   sudo nixos-rebuild switch --flake .#imac
# =====================================================================

{ inputs, config, ... }:

let
  system = "x86_64-linux";

  # ---- HARDWARE DESCRIPTION ---- #
  # Generated on the target machine, not stored in this repository until
  # the iMac has been installed.
  hardwareConfiguration = ../nixos/imac/hardware-configuration.nix;

  hardwareIsPresent = builtins.pathExists hardwareConfiguration;
in
{
  # ---- REUSABLE NIXOS HOST MODULE ---- #
  # Kept separate from the configuration below so the module stays
  # importable even before the machine has been installed.
  flake.nixosModules.imac = {
    imports = [
      # Provides the integrated Home Manager NixOS module
      inputs.home-manager.nixosModules.home-manager

      # Provides SOPS secret management
      inputs.sops-nix.nixosModules.sops

      # This machine's system and user configuration
      ../nixos/default.nix
      ../nixos/home-manager.nix
    ];
  };

  # ---- BUILDABLE SYSTEM ---- #
  # Only defined once the hardware description has been generated, so the
  # flake still evaluates cleanly on every other machine before then.
  flake.nixosConfigurations = inputs.nixpkgs.lib.optionalAttrs hardwareIsPresent {
    imac = config.flake.lib.mkNixosHost {
      inherit system;

      # Lets shared modules reference flake inputs when needed.
      extraSpecialArgs = {
        inherit inputs;
      };

      modules = [
        config.flake.nixosModules.imac
        hardwareConfiguration
      ];
    };
  };
}
