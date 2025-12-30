# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/services.nix
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
	environment.etc."hm-test-services.txt".text = ''
  services.nix was evaluated
	'';
  
  imports = [
    # Cleanup
    ./generations-cleanup.nix
    ./rsync-all.nix
    # ./rsync-all2.nix
    
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
    ./docker/vaultwarden/vaultwarden-android-cert.nix
  ];
}
