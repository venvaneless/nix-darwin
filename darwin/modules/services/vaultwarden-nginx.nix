# /Users/ven/dotfiles/nix/darwin/modules/services/vaultwarden-nginx.nix
#
# NGINX REVERSE PROXY FOR VAULTWARDEN (MINIMAL)
# ============================================================
# Makes Vaultwarden work on:
# - Safari
# - Android App
# - Bitwarden browser extension
# Always via https://vaultwarden.local
# ============================================================

{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;

    virtualHosts."vaultwarden.local" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@vaultwarden.local";
  };
}
