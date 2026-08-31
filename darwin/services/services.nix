# darwin/services/services.nix
#
# SERVICES AGGREGATOR
# ============================================================
# Loads ALL service modules:
#   - cleanup services
#   - Docker Desktop, containers, and Docker services
#   - Browsertrix, ArchiveBox, and Karakeep
#   - nginx
#   - mkcert
#   - vaultwarden stack
# ============================================================

{ ... }:

{
  # Enable the Wallabag, ArchiveBox, and Karakeep services
  services.wallabag.enable = true;
  services.archivebox.enable = true;
  services.karakeep.enable = true;
  services.browsertrix.enable = true;

  # Enable the custom nginx reverse proxy (com.ven.nginx-custom)
  ven.nginx.enable = true;


  imports = [

    # Docker + containers + tooling
    ./docker/docker.nix
    ./docker/browsertrix.nix
    ./docker/archivebox.nix
    ./docker/karakeep.nix
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
