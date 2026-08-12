# flake-modules/linux.nix
#
# =====================================================================
# LINUX HOST: ROG ZEPHYRUS
#
# Exposes the standalone Home Manager configuration for the regular
# Linux host without creating a NixOS system configuration.
# =====================================================================

{ config, inputs, ... }:

{
  # ---- STANDALONE HOME MANAGER ---- #
  flake.homeConfigurations.ven = config.flake.lib.mkStandaloneHome {
    system = "x86_64-linux";

    # Keeps shared modules able to reference flake inputs when needed.
    extraSpecialArgs = {
      inherit inputs;
    };

    # Uses the same unfree policy as the existing shared host modules.
    nixpkgsConfig.allowUnfree = true;

    modules = [
      ../linux/default.nix
    ];
  };
}
