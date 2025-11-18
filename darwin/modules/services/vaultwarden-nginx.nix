# /Users/ven/dotfiles/nix/darwin/modules/services/vaultwarden-nginx.nix
#
# HOMEBREW NGINX REVERSE PROXY FOR VAULTWARDEN
# ============================================================
# - Uses Homebrew-installed nginx binary
# - Generates a self-signed cert at:
#       ~/dotfiles/ssl/vaultwarden/
# - Writes nginx.conf to:
#       /opt/homebrew/etc/nginx/nginx.conf
# - Proxies:
#       https://vaultwarden.local  →  http://127.0.0.1:8080
# ============================================================

{ config, pkgs, lib, ... }:

let
  certDir = "/Users/ven/dotfiles/ssl/vaultwarden";
  cert    = "${certDir}/vaultwarden.local.pem";
  key     = "${certDir}/vaultwarden.local-key.pem";

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

      server {
        listen 443 ssl;
        server_name vaultwarden.local;

        ssl_certificate      ${cert};
        ssl_certificate_key  ${key};

        location / {
          proxy_pass http://127.0.0.1:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
        }
      }

      server {
        listen 80;
        server_name vaultwarden.local;
        return 301 https://vaultwarden.local$request_uri;
      }
    }
  '';

in
{

  # Generate certs once
  system.activationScripts.vaultwardenCert.text = ''
    mkdir -p ${certDir}

    if [ ! -f "${cert}" ] || [ ! -f "${key}" ]; then
      echo "Generating self-signed certificate for vaultwarden.local..."
      ${pkgs.openssl}/bin/openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout "${key}" \
        -out "${cert}" \
        -subj "/CN=vaultwarden.local" \
        -days 365
    fi
  '';

  # Write nginx.conf
  system.activationScripts.installNginxConf.text = ''
    echo "Installing nginx.conf to /opt/homebrew/etc/nginx/nginx.conf ..."
    mkdir -p /opt/homebrew/etc/nginx
    cat > /opt/homebrew/etc/nginx/nginx.conf <<EOF
${nginxConf}
EOF
  '';

  # Homebrew nginx launchd service
  launchd.daemons.nginx-vaultwarden = {
    serviceConfig = {
      Label = "homebrew.vaultwarden.nginx";

      ProgramArguments = [
        "/opt/homebrew/opt/nginx/bin/nginx"
        "-c"
        "/opt/homebrew/etc/nginx/nginx.conf"
        "-g"
        "daemon off;"
      ];

      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
