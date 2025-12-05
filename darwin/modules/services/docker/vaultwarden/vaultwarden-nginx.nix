# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-nginx.nix
#
# VAULTWARDEN: NGINX VHOST
# ============================================================
# - HTTP:
#       80 → redirect to HTTPS on vaultwarden.local or IP.
# - HTTPS:
#       443 → reverse proxy to Vaultwarden on http://127.0.0.1:8080
# - Uses certs created by vaultwarden-mkcert.nix:
#       ~/ven-dots/ssl/vaultwarden/vaultwarden.local.pem
#       ~/ven-dots/ssl/vaultwarden/vaultwarden.local-key.pem
# - Writes vhost to:
#       ~/ven-dots/conf/apps-enabled/vaultwarden.conf
# ============================================================

{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;

  confRoot = "${userHome}/ven-dots/conf";
  appsDir  = "${confRoot}/apps-enabled";

  certDir = "${userHome}/ven-dots/ssl/vaultwarden";
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  hostPort = config.ven.vaultwarden.hostPort or 8080;

  vhostFile   = "${appsDir}/vaultwarden.conf";

  vhostConfig = ''
    # AUTO-GENERATED VAULTWARDEN VHOST
    # HTTP → HTTPS, HTTPS → Vaultwarden

    # HTTP → HTTPS (hostname)
    server {
      listen 80;
      server_name vaultwarden.local;
      return 301 https://vaultwarden.local$request_uri;
    }

    # HTTP → HTTPS (IP)
    server {
      listen 80;
      server_name 192.168.2.125;
      return 301 https://192.168.2.125$request_uri;
    }

    # Helper map for websocket upgrade
    map $http_upgrade $connection_upgrade {
      default upgrade;
      ""      close;
    }

    # Main HTTPS server
    server {
      listen 443 ssl;
      server_name vaultwarden.local 192.168.2.125;

      ssl_certificate     ${certPem};
      ssl_certificate_key ${keyPem};

      location / {
        proxy_pass http://127.0.0.1:${toString hostPort};

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        $connection_upgrade;
      }
    }
  '';

  vhostScript = pkgs.writeShellScriptBin "vaultwarden-nginx-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-nginx] Writing Vaultwarden nginx vhost"
    echo ">>> [vw-nginx]   apps dir:  ${appsDir}"
    echo ">>> [vw-nginx]   vhost file: ${vhostFile}"

    mkdir -p "${appsDir}"

    cat > "${vhostFile}" <<'EOF'
${vhostConfig}
EOF

    echo ">>> [vw-nginx] Vaultwarden vhost written"
  '';
in
{
  # Helper script in PATH
  environment.systemPackages = [ vhostScript ];

  # Run at activation after nginx-setup has created appsDir
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-nginx-setup"
    ${vhostScript}/bin/vaultwarden-nginx-setup || echo "!!! vaultwarden-nginx-setup failed (continuing)"
  '';
}
