# flake-modules/imac-nix.nix
#
# =====================================================================
# MACHINE: 2015 INTEL IMAC
#
# Everything that would otherwise sit in flake.nix for this machine.
# Its configuration lives in imac/, the way the MacBook's lives in
# darwin/ and the Zephyrus's in nixos/.
#
# The host module is always exported. The buildable configuration only
# appears once the machine's own hardware description exists at:
#
#   imac/system/hardware-configuration.nix
#
# That file cannot be written here. It holds disk UUIDs, the filesystem
# layout, and the boot loader for the physical machine, so it has to be
# generated on the iMac itself:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > imac/system/hardware-configuration.nix
#
# After committing it, this file exposes nixosConfigurations.imac and:
#
#   sudo nixos-rebuild switch --flake .#imac
# =====================================================================

{ config, inputs, ... }:

let
  system = "x86_64-linux";

  # ---- HARDWARE DESCRIPTION ---- #
  # Generated on the target machine, not stored in this repository until
  # the iMac has been installed.
  hardwareConfiguration = ../imac/system/hardware-configuration.nix;

  hardwareIsPresent = builtins.pathExists hardwareConfiguration;
in
{
  # ---- STANDALONE HOME MANAGER ---- #
  # The iMac has its own user configuration; it does not share Zephyrus's.
  flake.homeConfigurations.imac = config.flake.lib.mkStandaloneHome {
    inherit system;

    extraSpecialArgs = {
      inherit inputs;
    };

    modules = [
      ../imac/home/default.nix
    ];
  };

  # ---- BUILDABLE SYSTEM ---- #
  # Only defined once the hardware description has been generated, so the
  # flake still evaluates cleanly on every other machine before then.
  flake.nixosConfigurations = inputs.nixpkgs.lib.optionalAttrs hardwareIsPresent {
    imac = config.flake.lib.mkNixosHost {
      inherit system;

      # Lets shared modules reference flake inputs when needed.
      # ** nixosSystem accepts specialArgs only, so this name matters.
      specialArgs = {
        inherit inputs;
      };

      modules = [
        # This machine's system configuration only.
        ../imac/default.nix
        hardwareConfiguration
      ];
    };
  };
}
