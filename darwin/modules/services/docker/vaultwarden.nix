# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden.nix
#
# VAULTWARDEN: CONTAINER + NGINX REVERSE PROXY
# ============================================================
# - Runs Vaultwarden Docker container via Docker Desktop
# - Data dir:
#       /Users/ven/ven-dots/user-data/containers/vaultwarden
# - TLS certs (mkcert leaf) stored under:
#       /Users/ven/ven-dots/ssl/vaultwarden
# - Supports:
#       https://vaultwarden.local
#       https://192.168.2.125
# - Generates:
#       PEM cert + KEY (once; if missing)
#       DER (.crt) for iOS/Android (always refreshed)
# - nginx.conf written to:
#       /opt/homebrew/etc/nginx/nginx.conf
# ============================================================

{ config, pkgs, lib, ... }:

let
  # BASE PATHS
  # ------------------------------------------------------------
  containersRoot = "/Users/ven/ven-dots/user-data/containers";
  sslRoot        = "/Users/ven/ven-dots/ssl";

  dockerBin      = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # VAULTWARDEN PATHS
  # ------------------------------------------------------------
  appName = "vaultwarden";
  dataDir = "${containersRoot}/${appName}";

  # CERTIFICATE PATHS
  # ------------------------------------------------------------
  certDir = "${sslRoot}/vaultwarden";

  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";
  certDer = "${certDir}/vaultwarden.local.crt";

  # VAULTWARDEN ENVIRONMENT VARIABLES
  # ------------------------------------------------------------
  envVars = [
    "-e" "WEBSOCKET_ENABLED=true"
    "-e" "ENABLE_DB_WAL=false"
    "-e" "ROCKET_LIMITS={forms=\"64KiB\"}"
    "-e" "PASSWORD_ITERATIONS=100000"
    "-e" "PASSWORD_HINTS=true"
  ];

  envString = lib.concatStringsSep " " envVars;

  # DOCKER START/RUN COMMAND
  # ------------------------------------------------------------
  # - If container exists: docker start vaultwarden
  # - Else: docker run -d ... vaultwarden/server:latest
  vaultwardenCommand =
    "${dockerBin} start ${appName} || " +
    "${dockerBin} run -d " +
      "--name ${appName} " +
      "-p 8080:80 " +
      "-v ${dataDir}:/data " +
      "${envString} " +
      "vaultwarden/server:latest";

  # NGINX CONFIGURATION TEMPLATE
  # ------------------------------------------------------------
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

      # WebSocket upgrade mapping for Vaultwarden
      map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ""      close;
      }

      # Main HTTPS block for hostname + IP
      server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name vaultwarden.local 192.168.2.125;

        # mkcert-generated leaf cert + key (PEM)
        ssl_certificate      ${certPem};
        ssl_certificate_key  ${keyPem};

        # Proxy all paths to Vaultwarden container
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
  # ACTIVATION: ENSURE DATA DIRECTORY EXISTS
  # ------------------------------------------------------------
  system.activationScripts.vaultwardenDataDir.text = ''
    echo ">>> [vaultwarden] ensuring data dir: ${dataDir}"
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"
    chmod 700 "${dataDir}"
  '';

  # ACTIVATION: ISSUE CERTS + WRITE NGINX CONFIG
  # ------------------------------------------------------------
  system.activationScripts.vaultwardenNginx.text = ''
    echo ">>> [vaultwarden-nginx] Activation start"
    echo ">>> [vaultwarden-nginx] cert PEM = ${certPem}"
    echo ">>> [vaultwarden-nginx] key  PEM = ${keyPem}"
    echo ">>> [vaultwarden-nginx] cert DER = ${certDer}"

    mkdir -p "${certDir}"

    # Generate leaf cert + key ONLY IF MISSING
    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vaultwarden-nginx] No certs found — generating with mkcert"
      "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \
        vaultwarden.local 192.168.2.125
    else
      echo ">>> [vaultwarden-nginx] Existing certs found — NOT regenerating"
    fi

    # Convert PEM cert to DER format (for iOS/Android)
    echo ">>> [vaultwarden-nginx] Converting PEM → DER for mobile"
    "${pkgs.openssl}/bin/openssl" x509 \
      -in "${certPem}" \
      -outform der \
      -out "${certDer}"

    # Write nginx.conf with the current certificate paths
    echo ">>> [vaultwarden-nginx] Writing nginx.conf"
    mkdir -p /opt/homebrew/etc/nginx
    cat > /opt/homebrew/etc/nginx/nginx.conf <<EOF
${nginxConf}
EOF

    echo ">>> [vaultwarden-nginx] Activation done"
  '';

  # LAUNCHD: VAULTWARDEN CONTAINER
  # ------------------------------------------------------------
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

  # LAUNCHD: NGINX REVERSE PROXY
  # ------------------------------------------------------------
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
