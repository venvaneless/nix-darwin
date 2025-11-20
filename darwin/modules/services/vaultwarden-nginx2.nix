# /Users/ven/dotfiles/nix/darwin/modules/services/vaultwarden-nginx.nix
#
# HOMEBREW NGINX REVERSE PROXY FOR VAULTWARDEN
# ============================================================
# - Uses Homebrew-installed nginx binary
# - Uses mkcert to generate a TLS cert for:
#       vaultwarden.local  AND  192.168.2.125
# - Cert is stored at:
#       ~/dotfiles/ssl/vaultwarden/vaultwarden.local+ip.pem
#       ~/dotfiles/ssl/vaultwarden/vaultwarden.local+ip-key.pem
# - Writes nginx.conf to:
#       /opt/homebrew/etc/nginx/nginx.conf
# - Proxies:
#       HTTPS  →  http://127.0.0.1:8080  (Vaultwarden container)
# - HTTP (80) redirects everything to HTTPS on vaultwarden.local
#   so:
#       http://192.168.2.125        → https://vaultwarden.local/...
#       http://vaultwarden.local    → https://vaultwarden.local/...
#       https://192.168.2.125       → valid TLS (same cert), hits Vaultwarden
# ============================================================

{ config, pkgs, lib, ... }:

let
  certDir = "/Users/ven/dotfiles/ssl/vaultwarden";
  cert    = "${certDir}/vaultwarden.local+ip.pem";
  key     = "${certDir}/vaultwarden.local+ip-key.pem";

  nginxConf = ''
    worker_processes  1;

    events {
      worker_connections  1024;
    }

    http {
      include       mime.types;
      default_type  application/octet-stream;
      sendfile      on;
      keepalive_timeout  65;

      # HTTP → HTTPS for hostname
      server {
        listen 80;
        server_name vaultwarden.local;
        return 301 https://vaultwarden.local$request_uri;
      }

      # HTTP → HTTPS for IP
      server {
        listen 80;
        server_name 192.168.2.125;
        return 301 https://192.168.2.125$request_uri;
      }

      # Main HTTPS server block
      server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name vaultwarden.local 192.168.2.125;

        ssl_certificate      ${cert};
        ssl_certificate_key  ${key};

        location / {
          proxy_pass http://127.0.0.1:8080;
          proxy_set_header Host              $host;
          proxy_set_header X-Real-IP         $remote_addr;
          proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Upgrade           $http_upgrade;
          proxy_set_header Connection        $connection_upgrade;
        }
      }
    }
  '';

in
{
  # ----- Generate certs with mkcert -----
  system.activationScripts.vaultwardenCert.text = ''
    echo ">>> vaultwardenCert: ensuring mkcert certs"

    mkdir -p "${certDir}"

    # If new files needed, generate them
    if [ ! -f "${cert}" ] || [ ! -f "${key}" ]; then
      echo ">>> Creating certificate via mkcert..."
      "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${cert}" \
        -key-file "${key}" \
        vaultwarden.local 192.168.2.125
    else
      echo ">>> Certificate already exists, skipping"
    fi
  '';

  # ----- Install nginx.conf -----
  system.activationScripts.installNginxConf.text = ''
    echo ">>> Installing nginx.conf"
    mkdir -p /opt/homebrew/etc/nginx
    cat > /opt/homebrew/etc/nginx/nginx.conf <<EOF
${nginxConf}
EOF
  '';

  launchd.daemons.nginx-vaultwarden = {
    serviceConfig = {
      Label = "homebrew.vaultwarden.nginx";
      ProgramArguments = [
        "/opt/homebrew/opt/nginx/bin/nginx"
        "-c" "/opt/homebrew/etc/nginx/nginx.conf"
        "-g" "daemon off;"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
