# darwin/modules/system/base.nix
{ config, pkgs, lib, inputs, ... }:

{
  # --- Core system identity ---
  networking.hostName = "Vens-MacBook-Pro";

  # Tell nix‑darwin to manage /etc/nix/nix.conf for us
  nix.enable = true;

  # --- Enable new Nix CLI and flakes, and configure caches ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    build-users-group = "nixbld";

    # Use only the official cache for now; this removes the bad key permanently
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

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
