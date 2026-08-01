# darwin/services/services.nix
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
  # Enable the 'Wallabag' service
  services.wallabag.enable = true;


  imports = [

  	# Background services
   	./startpage-launchd.nix
    
    # Docker + containers + tooling
    ./docker/docker.nix
    ./docker/wallabag.nix
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
