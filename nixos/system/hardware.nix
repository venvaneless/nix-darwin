# nixos/system/hardware.nix
#
# =====================================================================
# ZEPHYRUS: HARDWARE
#
# Everything hardware-configuration.nix does not describe: redistributable
# firmware, the ROG service daemons, and the hybrid graphics setup.
#
# ** Every value marked TARGET has to be read off the laptop itself and
# ** cannot be written here in advance.
# =====================================================================

{ ... }:

{
  # ---- FIRMWARE ---- #
  # Wi-Fi, Bluetooth, and GPU firmware that is redistributable but not
  # free, so it is not included by default.
  hardware.enableRedistributableFirmware = true;

  # ---- FIRMWARE UPDATES ---- #
  # ASUS publishes UEFI updates through LVFS, so fwupdmgr can apply them
  # without a Windows installation.
  services.fwupd.enable = true;

  # ---- ROG DAEMONS ---- #
  # asusd owns the keyboard backlight, the fan curves, and the platform
  # profiles. supergfxd switches graphics mode without reinstalling
  # drivers.
  #
  # ** asusd also has enableUserService, which adds the per-user daemon
  # ** the asusctl tray needs. Left off until there is a desktop session
  # ** to put a tray in.
  services.asusd.enable = true;

  services.supergfxd.enable = true;

  # ---- TOUCHPAD ---- #
  # Wayland reads libinput directly; this enables the daemon and its
  # defaults for tapping and natural scrolling.
  services.libinput.enable = true;

  # ---- BLUETOOTH ---- #
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # ---- HYBRID GRAPHICS ---- #
  # TARGET: this block stays commented until the laptop reports its own
  # PCI bus IDs. Read them with:
  #
  #   lspci | grep -E 'VGA|3D'
  #
  # and write each one in "PCI:bus:device:function" form, in decimal --
  # lspci prints hexadecimal, so 0a:00.0 becomes PCI:10:0:0.
  #
  # ** Which integrated key applies depends on the model: amdgpuBusId on
  # ** the AMD Zephyrus models, intelBusId on the Intel ones.
  #
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = true;
  #
  #   # The open kernel modules require Turing or newer.
  #   open = false;
  #
  #   prime = {
  #     offload = {
  #       enable = true;
  #       enableOffloadCmd = true;
  #     };
  #
  #     amdgpuBusId = "PCI:0:0:0";   # TARGET
  #     nvidiaBusId = "PCI:0:0:0";   # TARGET
  #   };
  # };
  #
  # services.xserver.videoDrivers = [ "nvidia" ];

  # ---- NIXOS-HARDWARE ---- #
  # ** github:NixOS/nixos-hardware maintains a profile for this laptop
  # ** family that would replace most of the block above. It is not a
  # ** flake input yet, on purpose: the exact model decides which profile
  # ** applies (asus-zephyrus-ga401, ga402x, gu603h, and others). Add the
  # ** input and import the matching module once the model is confirmed.
}
