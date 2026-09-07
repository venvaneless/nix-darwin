# flake-modules/linux.nix
#
# =====================================================================
# MACHINE: ROG ZEPHYRUS
#
# Everything that would otherwise sit in flake.nix for this machine.
# Its configuration lives in nixos/, the way the MacBook's lives in
# darwin/ and the iMac's in imac/.
#
# The standalone user configuration and the future system configuration
# are separate outputs. Neither imports the other:
#
#   homeConfigurations.zephyrus
#     Manages the user only, on top of whatever distribution is currently
#     installed:
#
#       home-manager switch --flake .#zephyrus
#
#   nixosConfigurations.zephyrus
#     This machine's system modules in nixos/. It appears only once the
#     machine's own hardware description exists at
#     nixos/system/hardware-configuration.nix.
#
# That file cannot be written here. It holds disk UUIDs, the filesystem
# layout, and the boot loader for the physical machine, so it has to be
# generated on the laptop itself:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > nixos/system/hardware-configuration.nix
#
# After committing it:
#
#   sudo nixos-rebuild switch --flake .#zephyrus
#
# =====================================================================

{ config, inputs, ... }:

let
  system = "x86_64-linux";

  # ---- Variables from options/default.nix
  # The nixpkgs policy is defined once there and read by every machine.
  inherit (import ../options { }) nixpkgsConfig;

  # ---- HARDWARE DESCRIPTION ---- #
  # Generated on the target machine, not stored in this repository until
  # the laptop has been installed.
  hardwareConfiguration = ../nixos/system/hardware-configuration.nix;

  hardwareIsPresent = builtins.pathExists hardwareConfiguration;
in
{
  # ---- STANDALONE HOME MANAGER ---- #
  # This machine's user configuration remains usable before NixOS exists.
  flake.homeConfigurations.zephyrus = config.flake.lib.mkStandaloneHome {
    inherit system;

    # Keeps shared modules able to reference flake inputs when needed
    extraSpecialArgs = {
      inherit inputs;
    };

    # The shared policy, identical to every other machine
    inherit nixpkgsConfig;

    modules = [
      ../nixos/home/default.nix
    ];
  };

  # ---- BUILDABLE SYSTEM ---- #
  # Only defined once the hardware description has been generated, so the
  # flake still evaluates cleanly on every other machine before then.
  flake.nixosConfigurations = inputs.nixpkgs.lib.optionalAttrs hardwareIsPresent {
    zephyrus = config.flake.lib.mkNixosHost {
      inherit system;

      # Lets shared modules reference flake inputs when needed.
      # ** nixosSystem accepts specialArgs only, so this name matters.
      specialArgs = {
        inherit inputs;
      };

      modules = [
        # This machine's system configuration only.
        ../nixos/default.nix

        hardwareConfiguration
      ];
    };
  };
}
