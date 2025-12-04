# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/script-services.nix
#
# CLEANUP SERVICES AGGREGATOR
# ============================================================
# Loads all maintenance/cleanup modules.
# Imported once in darwin/index.nix.
# ============================================================

{ ... }:

{
	imports = [
    ./script-services.nix

    # Docker + containers + tooling
    ./docker/docker.nix
    ./docker/containers.nix
    ./docker/mkcert.nix
    ./docker/nginx.nix

    # Vaultwarden stack
    ./docker/vaultwarden/vaultwarden.nix
    ./docker/vaultwarden/vaultwarden-service.nix
    ./docker/vaultwarden/vaultwarden-mkcert.nix
    ./docker/vaultwarden/vaultwarden-nginx.nix
  ];
}
