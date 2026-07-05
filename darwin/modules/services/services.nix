# /Users/ven/.config/nix/nix-config/darwin/modules/services/services.nix
#
# SERVICES AGGREGATOR
# ============================================================
# Loads ALL service modules:
#   - cleanup services
#   - docker + containers
#   - nginx
#   - mkcert
#   - vaultwarden stack
# ============================================================

{ ... }:

{
  imports = [

  	# Background services
   	./startpage-launchd.nix
   	
    # Cleanup
    ./generations-cleanup.nix
    ./rsync.nix
    
    # Docker + containers + tooling
    ./docker/docker.nix
    ./docker/containers.nix
    ./docker/mkcert.nix
    ./docker/nginx.nix

    # Docker - Vaultwarden stack
    ./docker/vaultwarden/vaultwarden.nix
    ./docker/vaultwarden/vaultwarden-service.nix
    ./docker/vaultwarden/vaultwarden-mkcert.nix
    ./docker/vaultwarden/vaultwarden-nginx.nix
    ./docker/vaultwarden/vaultwarden-android-cert.nix
  ];
}
