# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden.nix
#
# VAULTWARDEN: CONTAINER + NGINX REVERSE PROXY
# ============================================================
# PURPOSE:
#   - Run Vaultwarden as a Docker container via Docker Desktop
#   - Store Vaultwarden data under:
#         /Users/ven/ven-dots/user-data/containers/vaultwarden
#   - Automatically generate TLS leaf certs (PEM + DER) using mkcert
#   - Serve Vaultwarden via nginx on:
#         https://vaultwarden.local
#         https://192.168.2.125
#
# DATA MIGRATION NOTE:
#   - If you previously had a Vaultwarden container bound to:
#         /Users/ven/dotfiles/containers/vaultwarden:/data
#     you must run once:
#         docker stop vaultwarden || true
#         docker rm vaultwarden  || true
#     so that the Nix-managed command can recreate it with the
#     correct volume:
#         /Users/ven/ven-dots/user-data/containers/vaultwarden:/data
#
# CERT MANAGEMENT:
#   - TLS certs are stored in:
#         /Users/ven/ven-dots/ssl/vaultwarden
#   - On each activation, mkcert regenerates *leaf* certs for:
#         vaultwarden.local AND 192.168.2.125
#   - The mkcert root CA is NOT touched here
#
# NGINX:
#   - Writes nginx.conf to:
#         /opt/homebrew/etc/nginx/nginx.conf
#   - Proxies:
#         HTTPS → http://127.0.0.1:8080  (Vaultwarden container)
#   - HTTP (80) redirects everything to HTTPS on vaultwarden.local or IP
# ============================================================

{ config, pkgs, lib, ... }:

let
  # BASE PATHS
  # ------------------------------------------------------------
  # Canonical directory for all container data
  containersRoot = "/Users/ven/ven-dots/user-data/containers";

  # Base directory for all SSL / TLS material
  sslRoot        = "/Users/ven/ven-dots/ssl";

  # Path to Docker CLI inside Docker Desktop bundle
  dockerBin      = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # VAULTWARDEN PATHS
  # ------------------------------------------------------------
  # Container name (used by Docker and launchd)
  appName = "vaultwarden";

  # Data dir for Vaultwarden (host side)
  dataDir = "${containersRoot}/${appName}";

  # CERTIFICATE PATHS
  # ------------------------------------------------------------
  # Folder for Vaultwarden-specific certs
  certDir  = "${sslRoot}/vaultwarden";

  # PEM certificate used by nginx (leaf cert)
  certPem  = "${certDir}/vaultwarden.local.pem";

  # PEM private key for nginx
  keyPem   = "${certDir}/vaultwarden.local-key.pem";

  # DER version of the leaf cert (for optional mobile import)
  certDer  = "${certDir}/vaultwarden.local.crt";

  # VAULTWARDEN ENVIRONMENT VARIABLES
  # ------------------------------------------------------------
  # Container env flags that tune Vaultwarden runtime behavior
  envVars = [
    "-e" "WEBSOCKET_ENABLED=true"
    "-e" "ENABLE_DB_WAL=false"
    "-e" "ROCKET_LIMITS={forms=\"64KiB\"}"
    "-e" "PASSWORD_ITERATIONS=100000"
    "-e" "PASSWORD_HINTS=true"
  ];

  # Join the env flags into a single shell string
  envString = lib.concatStringsSep " " envVars;

  # DOCKER START/RUN COMMAND
  # ------------------------------------------------------------
  # On a fresh system (or after `docker rm vaultwarden`), this will
  # create a new container that binds:
  #   /Users/ven/ven-dots/user-data/containers/vaultwarden → /data
  #
  # On subsequent runs, `docker start` will reuse that container.
  vaultwardenCommand =
    "${dockerBin} start ${appName} || " +
    "${dockerBin} run -d " +
      "--name ${appName} " +
      "-p 8080:80 " +  # Publishes container port 80 as host port 8080
      "-v ${dataDir}:/data " +  # Mounts host dataDir into container /data
      "${envString} " +         # Injects environment vars into container
      "vaultwarden/server:latest";

  # NGINX CONFIGURATION TEMPLATE
  # ------------------------------------------------------------
  # This string becomes /opt/homebrew/etc/nginx/nginx.conf at activation.
  # It:
  #   - redirects HTTP → HTTPS for hostname and IP
  #   - terminates TLS using mkcert-generated PEM files
  #   - proxies requests to 127.0.0.1:8080 (Vaultwarden container)
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
  # Creates the base container root and Vaultwarden data dir
  # with secure permissions before Docker ever touches them.
  system.activationScripts.vaultwardenDataDir.text = ''
    # Create containers root (if missing)
    mkdir -p "${containersRoot}"

    # Create Vaultwarden data directory under containers root
    mkdir -p "${dataDir}"

    # Lock down permissions on the Vaultwarden data directory
    chmod 700 "${dataDir}"
  '';

  # ACTIVATION: ISSUE CERTS + WRITE NGINX CONFIG
  # ------------------------------------------------------------
  # On each activation, this script:
  #   1. Ensures the cert directory exists
  #   2. Uses mkcert to (re)issue a *leaf* cert + key for:
  #        - vaultwarden.local
  #        - 192.168.2.125
  #   3. Converts the PEM cert to DER format for optional mobile import
  #   4. Writes nginx.conf using the nginxConf template above
  #
  # It explicitly does NOT:
  #   - run `mkcert -install`
  #   - touch the mkcert root CA or CAROOT
  system.activationScripts.vaultwardenNginx.text = ''
    echo ">>> [vaultwarden-nginx] Activation start"
    echo ">>> [vaultwarden-nginx] cert PEM = ${certPem}"
    echo ">>> [vaultwarden-nginx] key  PEM = ${keyPem}"
    echo ">>> [vaultwarden-nginx] cert DER = ${certDer}"

    # Ensure certificate directory exists
    mkdir -p "${certDir}"

    # (Re)issue leaf cert + key for hostname + IP
    echo ">>> [vaultwarden-nginx] (Re)issuing leaf cert with mkcert"
    "${pkgs.mkcert}/bin/mkcert" \
      -cert-file "${certPem}" \
      -key-file  "${keyPem}" \
      vaultwarden.local 192.168.2.125

    # Convert PEM cert to DER format (for iOS/Android if needed)
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
  '';

  # LAUNCHD: VAULTWARDEN CONTAINER
  # ------------------------------------------------------------
  # Launchd daemon that:
  #   - runs the vaultwardenCommand shell snippet at boot
  #   - starts the existing container, or creates it if missing
  launchd.daemons.vaultwarden = {
    serviceConfig = {
      # Unique label for the Vaultwarden container daemon
      Label = "com.ven.vaultwarden";

      # Run the docker start/run logic via /bin/sh -c
      ProgramArguments = [
        "/bin/sh"
        "-c"
        vaultwardenCommand
      ];

      # Start on load and restart if it dies
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # LAUNCHD: NGINX REVERSE PROXY
  # ------------------------------------------------------------
  # Launchd daemon that:
  #   - runs Homebrew nginx in foreground (daemon off)
  #   - uses the generated nginx.conf for TLS + proxy config
  launchd.daemons.nginx-vaultwarden = {
    serviceConfig = {
      # Unique label for the nginx instance serving Vaultwarden
      Label = "homebrew.vaultwarden.nginx";

      # Invoke nginx with explicit config path and 'daemon off'
      ProgramArguments = [
        "/opt/homebrew/opt/nginx/bin/nginx"
        "-c" "/opt/homebrew/etc/nginx/nginx.conf"
        "-g" "daemon off;"
      ];

      # Start on load and keep it running
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
