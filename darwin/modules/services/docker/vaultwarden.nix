# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden.nix
#
# VAULTWARDEN: CONTAINER + NGINX REVERSE PROXY
# ============================================================
# - Runs Vaultwarden as a Docker container via Docker Desktop.
# - Data is stored in:
#       /Users/ven/ven-dots/user-data/containers/vaultwarden
# - TLS certs are stored in:
#       /Users/ven/ven-dots/ssl/vaultwarden
# - Uses mkcert to generate a TLS cert for:
#       vaultwarden.local AND 192.168.2.125
# - Writes nginx.conf to:
#       /opt/homebrew/etc/nginx/nginx.conf
# - Proxies:
#       HTTPS  →  http://127.0.0.1:8080  (Vaultwarden container)
# - HTTP (80) redirects everything to HTTPS on vaultwarden.local or IP
# ============================================================

{ config, pkgs, lib, ... }:

let
  # ----- Base paths -----
  containersRoot = "/Users/ven/ven-dots/user-data/containers";
  sslRoot        = "/Users/ven/ven-dots/ssl";
  dockerBin      = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # ----- Vaultwarden paths -----
  appName = "vaultwarden";
  dataDir = "${containersRoot}/${appName}";

  # ----- Certificate paths -----
  certDir = "${sslRoot}/vaultwarden";
  cert    = "${certDir}/vaultwarden.local.pem";
  key     = "${certDir}/vaultwarden.local-key.pem";

  # ----- Environment variables for Vaultwarden -----
  envVars = [
    "-e" "WEBSOCKET_ENABLED=true"
    "-e" "ENABLE_DB_WAL=false"
    "-e" "ROCKET_LIMITS={forms=\"64KiB\"}"
    "-e" "PASSWORD_ITERATIONS=100000"
    "-e" "PASSWORD_HINTS=true"
  ];

  # Convert env list to string
  envString = lib.concatStringsSep " " envVars;

  # ----- Shell command: start or create container -----
  vaultwardenCommand =
    "${dockerBin} start ${appName} || " +
    "${dockerBin} run -d " +
      "--name ${appName} " +
      "-p 8080:80 " +  # NOTE: trailing space to avoid concatenation bugs
      "-v ${dataDir}:/data " +
      "${envString} " +
      "vaultwarden/server:latest";

  # ----- Nginx configuration -----
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

      # HTTP → HTTPS for hostname
      server {
        listen 80;
        server_name vaultwarden.local;
        return 301 https://vaultwarden.local\$request_uri;
      }

      # HTTP → HTTPS for IP
      server {
        listen 80;
        server_name 192.168.2.125;
        return 301 https://192.168.2.125\$request_uri;
      }

      # WebSocket upgrade mapping
      map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ""      close;
      }

      # Main HTTPS block
      server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name vaultwarden.local 192.168.2.125;

        ssl_certificate      ${cert};
        ssl_certificate_key  ${key};

        location / {
          proxy_pass http://127.0.0.1:8080;

          proxy_set_header Host              \$host;
          proxy_set_header X-Real-IP         \$remote_addr;
          proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto \$scheme;
          proxy_set_header Upgrade           \$http_upgrade;
          proxy_set_header Connection        \$connection_upgrade;
        }
      }
    }
  '';

in
{
  # ----- Ensure data directory exists -----
  system.activationScripts.vaultwardenDataDir.text = ''
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"
    chmod 700 "${dataDir}"
  '';

  # ----- Ensure certs exist + write nginx.conf -----
  system.activationScripts.vaultwardenNginx.text = ''
    echo ">>> [vaultwarden-nginx] Activation start"
    echo ">>> [vaultwarden-nginx] cert path = ${cert}"
    echo ">>> [vaultwarden-nginx] key  path = ${key}"

    mkdir -p "${certDir}"

    if [ ! -f "${cert}" ] || [ ! -f "${key}" ]; then
      echo ">>> [vaultwarden-nginx] Running mkcert"
      "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${cert}" \
        -key-file  "${key}" \
        vaultwarden.local 192.168.2.125
    else
      echo ">>> [vaultwarden-nginx] Cert already exists"
    fi

    echo ">>> [vaultwarden-nginx] Writing nginx.conf"
    mkdir -p /opt/homebrew/etc/nginx
    cat > /opt/homebrew/etc/nginx/nginx.conf <<EOF
${nginxConf}
EOF
  '';

  # ----- Vaultwarden container launchd daemon -----
  launchd.daemons.vaultwarden = {
    serviceConfig = {
      Label = "com.ven.vaultwarden";

      ProgramArguments = [
        "/bin/sh"
        "-c"
        vaultwardenCommand
      ];

      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # ----- Nginx reverse proxy launchd daemon -----
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
