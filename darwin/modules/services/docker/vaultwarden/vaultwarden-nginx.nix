# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-nginx.nix
#
# VAULTWARDEN: NGINX REVERSE PROXY
# =================================
# - Uses services.nginx (from nginx.nix) to:
#     - terminate TLS for:
#         - vaultwarden.local
#         - 192.168.2.125
#     - proxy to Vaultwarden container on 127.0.0.1:8080
#     - support WebSockets
#     - optionally redirect HTTP → HTTPS
# =================================

{ config, pkgs, lib, ... }:

let
  certDir = "/Users/ven/ven-dots/ssl/vaultwarden";
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  hostPort = config.ven.vaultwarden.hostPort or 8080;

  commonVHost = {
    forceSSL       = true;
    enableACME     = false;
    sslCertificate = certPem;
    sslCertificateKey = keyPem;

    # HTTP → HTTPS redirection
    addSSL = true;

    locations."/" = {
      proxyPass        = "http://127.0.0.1:${toString hostPort}";
      proxyWebsockets  = true;
      extraConfig = ''
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
in
{
  services.nginx.virtualHosts = {
    "vaultwarden.local" = commonVHost;
    "192.168.2.125"     = commonVHost;
  };
}
