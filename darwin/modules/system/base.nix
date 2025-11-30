# /Users/ven/dotfiles/nix/darwin/modules/system/base.nix
#
# CORE CONFIG
# ============================================================
# BASE CONFIG
# Enable flakes, small services, expose additional flags
# and commands for the "nix-darwin" etc.
# ============================================================

{ config, pkgs, lib, inputs, ... }:

{
  # --- Core system identity ---
  networking.hostName = "Vens-MacBook-Pro";

  # --- Enable new Nix CLI and flakes ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    build-users-group = "nixbld";

    # Use the Nix Community binary cache
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # --- Enable Nix Determine ---
  nix.enable = false;

  # --- System state version (Darwin revision) ---
  system.stateVersion = 6;

  # --- Global system packages ---
  environment.systemPackages = with pkgs; [
    inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild
    bashInteractive
    git-crypt
    nh
    home-manager
    mkcert
    nssTools
    nginx
    nixd
    nil
  ];
}
