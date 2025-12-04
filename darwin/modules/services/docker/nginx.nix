# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/nginx.nix
#
# NGINX: GLOBAL SETUP
# ===================
# - Enables Nix-managed nginx (nix-darwin/NixOS services.nginx).
# - Uses the nginx package from Nixpkgs.
# - Per-app configs (like Vaultwarden) extend services.nginx.virtualHosts.
# ===================

{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable  = true;
    package = pkgs.nginx;

    # Sensible defaults from NixOS module
    recommendedGzipSettings  = true;
    recommendedProxySettings = true;
    recommendedTlsSettings   = true;

    # No virtualHosts defined here – app modules (Vaultwarden, Browsertrix, etc.)
    # will add their own virtualHosts.* entries.
  };
}
