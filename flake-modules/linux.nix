# flake-modules/linux.nix
#
# =====================================================================
# LINUX HOST: ROG ZEPHYRUS
#
# Everything that would otherwise sit in flake.nix for this machine.
#
# The machine is moving from standalone Home Manager to NixOS. Both are
# declared here so nothing breaks during the move:
#
#   homeConfigurations.ven
#     Always available. Manages the user only, on top of whatever
#     distribution is currently installed:
#
#       home-manager switch --flake .#ven
#
#   nixosConfigurations.zephyrus
#     Appears only once the machine's own hardware description exists at
#     nixos/zephyrus/hardware-configuration.nix.
#
# That file cannot be written here. It holds disk UUIDs, the filesystem
# layout, and the boot loader for the physical machine, so it has to be
# generated on the laptop itself:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > nixos/zephyrus/hardware-configuration.nix
#
# After committing it:
#
#   sudo nixos-rebuild switch --flake .#zephyrus
#
# The standalone Home Manager output can be removed once that works.
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
  hardwareConfiguration = ../nixos/zephyrus/hardware-configuration.nix;

  hardwareIsPresent = builtins.pathExists hardwareConfiguration;
in
{
  # ---- STANDALONE HOME MANAGER ---- #
  # The current, working configuration for this machine.
  flake.homeConfigurations.ven = config.flake.lib.mkStandaloneHome {
    inherit system;

    # Keeps shared modules able to reference flake inputs when needed
    extraSpecialArgs = {
      inherit inputs;
    };

    # The shared policy, identical to every other machine
    inherit nixpkgsConfig;

    modules = [
      # Provides SOPS secret management
      inputs.sops-nix.homeManagerModules.sops

      ../linux/default.nix
    ];
  };

  # ---- BUILDABLE SYSTEM ---- #
  # Only defined once the hardware description has been generated, so the
  # flake still evaluates cleanly on every other machine before then.
  #
  # The system and user modules under nixos/zephyrus/ do not exist yet.
  # They are written when the laptop is installed, at which point this
  # whole block starts producing nixosConfigurations.zephyrus.
  flake.nixosConfigurations = inputs.nixpkgs.lib.optionalAttrs hardwareIsPresent {
    zephyrus = config.flake.lib.mkNixosHost {
      inherit system;

      # Lets shared modules reference flake inputs when needed.
      extraSpecialArgs = {
        inherit inputs;
      };

      modules = [
        # Provides the integrated Home Manager NixOS module
        inputs.home-manager.nixosModules.home-manager

        # Provides SOPS secret management
        inputs.sops-nix.nixosModules.sops

        # This machine's system and user configuration
        ../nixos/zephyrus/default.nix
        ../nixos/zephyrus/home-manager.nix

        hardwareConfiguration
      ];
    };
  };
}
