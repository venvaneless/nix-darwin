# /Users/ven/dotfiles/nix/darwin/modules/services/vaultwarden-nginx.nix
#
# NGINX VIA HOMEBREW (DECLARATIVE CONFIG)
# ============================================================

{ config, pkgs, ... }:

let
  certDir = "/Users/ven/dotfiles/ssl/vaultwarden";
  cert    = "${certDir}/cert.pem";
  key     = "${certDir}/key.pem";

  nginxConf = ''
    worker_processes 1;

    events {
      worker_connections 1024;
    }

    http {
      include mime.types;
      default_type application/octet-stream;
      sendfile on;
      keepalive_timeout 65;

      server {
        listen 443 ssl;
        server_name vaultwarden.local;

        ssl_certificate      /Users/ven/dotfiles/ssl/vaultwarden/vaultwarden.local.pem;
        ssl_certificate_key  /Users/ven/dotfiles/ssl/vaultwarden/vaultwarden.local-key.pem;

        location / {
          proxy_pass http://127.0.0.1:8080;

          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_set_header Upgrade $http_upgrade;

          if ($http_upgrade != "") {
            proxy_set_header Connection "upgrade";
          } else {
            proxy_set_header Connection "close";
          }
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
  # ❌ Remove this if still present
  # environment.etc."opt/homebrew/etc/nginx/nginx.conf".text = nginxConf;

  # CERT GENERATOR
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

  # NGINX CONFIG INSTALLER — FIXED VERSION
  system.activationScripts.installNginxConf.text = ''
    mkdir -p /opt/homebrew/etc/nginx

    echo "Installing nginx.conf into Homebrew prefix..."
    cat > /opt/homebrew/etc/nginx/nginx.conf <<EOF
${nginxConf}
EOF
  '';

  launchd.daemons.nginx = {
     serviceConfig = {
       Label = "homebrew.mxcl.nginx";
 
       ProgramArguments = [
         "/opt/homebrew/opt/nginx/bin/nginx"
         "-c"
         "/opt/homebrew/etc/nginx/nginx.conf"
         "-g"
         "daemon off;"
       ];
 
       RunAtLoad = true;
       KeepAlive = true;
       WorkingDirectory = "/opt/homebrew";
     };
   };
   
   
  # Optional message
  system.activationScripts.vaultwardenNginxMessage.text = ''
    echo ">> Restarting nginx recommended: brew services restart nginx"
  '';
}
