# nixos/default.nix
#
# =====================================================================
# NIXOS HOST: 2015 INTEL MAC
#
# Machine-independent NixOS settings for the supplied host identity.
# Hardware, storage, boot, GPU, and network hardware configuration stay
# outside this module until generated from the target machine.
# =====================================================================

{ pkgs, ... }:

{
  imports = [
    # ---- SHARED NIXPKGS POLICY ---- #
    ../shared/hosts.nix
  ];

  # ===================================================================
  # REQUIRED TARGET HARDWARE MODULE
  # -------------------------------------------------------------------
  # Before deployment, generate hardware-configuration.nix on the
  # target and add it to flake-modules/nixos.nix beside this module.
  # It must define the real boot loader, file systems, and hardware.
  # ===================================================================

  # ---- HOST IDENTITY ---- #
  networking.hostName = "ven";

  # ---- NIXOS COMPATIBILITY ---- #
  # This is a new NixOS installation using the pinned 26.05 release.
  system.stateVersion = "26.05";

  # ---- FISH LOGIN SHELL ---- #
  programs.fish.enable = true;

  # ---- PRIMARY USER ---- #
  users.users.ven = {
    isNormalUser = true;
    home = "/home/ven";
    shell = pkgs.fish;
  };
}
