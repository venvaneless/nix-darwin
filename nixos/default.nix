# nixos/default.nix
#
# =====================================================================
# MACHINE: ROG ZEPHYRUS
#
# This machine's entry point, the way darwin/default.nix is the
# MacBook's. Only what is true of this laptop and no other lives under
# nixos/.
#
# The disks, boot device, kernel modules, and swap arrive with
# hardware-configuration.nix, which has to be generated on the laptop:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > nixos/system/hardware-configuration.nix
#
# flake-modules/linux.nix only produces nixosConfigurations.zephyrus once
# that file exists, so the flake keeps evaluating on every other machine
# until then.
# =====================================================================

{ paths, pkgs, ... }:

{
  imports = [
    # ---- MACHINE HARDWARE ---- #
    # Vendor firmware, the ROG service daemons, and hybrid graphics.
    ./system/hardware.nix

    # ---- DESKTOP ---- #
    # Hyprland, its portals, the greeter, and audio.
    ./system/hyprland.nix
  ];

  # ---- HOST IDENTITY ---- #
  # Also the flake attribute: nixosConfigurations.zephyrus.
  networking.hostName = "zephyrus";

  # ---- BOOT LOADER ---- #
  # ** systemd-boot needs a UEFI installation, which is what this machine
  # ** generation ships with. Swap both lines for boot.loader.grub if the
  # ** laptop is ever installed in legacy BIOS mode. The ESP mount point
  # ** itself comes from hardware-configuration.nix either way.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- NETWORKING ---- #
  # NetworkManager owns wireless on a laptop, so wpa_supplicant stays off.
  networking.networkmanager.enable = true;

  # ---- TIME AND LOCALE ---- #
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  # ** The console keymap describes the physical keyboard, not the
  # ** interface language. The Wayland session takes its own layout from
  # ** Hyprland's input section rather than from this value.
  console.keyMap = "us";

  # ---- PRIMARY USER ---- #
  # This is a normal local account. The groups make it usable on this
  # laptop: sudo, NetworkManager, and the video and input devices a
  # Wayland session opens directly.
  #
  # ** No password is set declaratively. Set one with passwd after the
  # ** first boot, or point users.users.<name>.hashedPasswordFile at a
  # ** sops secret once this host has an age key in .sops.yaml.
  users.users.${paths.user.name} = {
    isNormalUser = true;
    home = paths.user.linuxHome;
    shell = pkgs.fish;

    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
  };

  # ---- NIXOS COMPATIBILITY ---- #
  # Keep this at the first installed NixOS release for this machine.
  system.stateVersion = "26.05";

  # ---- FISH LOGIN SHELL ---- #
  # Enables the shell selected for the local account above.
  programs.fish.enable = true;
}
