# imac/default.nix
#
# =====================================================================
# MACHINE: 2015 INTEL IMAC
#
# This machine's entry point, the way darwin/default.nix is the
# MacBook's and nixos/default.nix is the Zephyrus's. Only what is true of
# this iMac lives under imac/.
#
# The boot loader, file systems, and hardware arrive with
# hardware-configuration.nix once it has been generated on the iMac:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > imac/system/hardware-configuration.nix
#
# ** Apple hardware of this generation needs more than the generated
# ** file: Broadcom wireless firmware, applesmc fan control, and the
# ** hid_apple function-key mode. Those belong in imac/system/ when the
# ** machine is installed, the way nixos/system/hardware.nix holds the
# ** Zephyrus's.
# =====================================================================

{ paths, pkgs, ... }:

{
  # ---- HOST IDENTITY ---- #
  # Also the flake attribute: nixosConfigurations.imac.
  networking.hostName = "imac";

  # ---- PRIMARY USER ---- #
  # The standalone Home Manager module configures this account's files.
  # NixOS still owns the local account and its login shell.
  users.users.${paths.user.name} = {
    isNormalUser = true;
    home = paths.user.linuxHome;
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
  };

  # ---- NIXOS COMPATIBILITY ---- #
  # Keep this at the first installed NixOS release for this machine.
  system.stateVersion = "26.05";

  # ---- FISH LOGIN SHELL ---- #
  # Enables the shell selected for the local account above.
  programs.fish.enable = true;
}
