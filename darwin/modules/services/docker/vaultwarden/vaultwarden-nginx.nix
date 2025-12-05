{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;

  confRoot = "${userHome}/ven-dots/conf";
  appsDir  = "${confRoot}/apps-enabled";

  certDir = "${userHome}/ven-dots/ssl/vaultwarden";
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  hostPort = config.ven.vaultwarden.hostPort;

  vhostFile = "${appsDir}/vaultwarden.conf";

  vhost = ''
    server {
      listen 80;
      server_name vaultwarden.local 192.168.2.125;
      return 301 https://$server_name$request_uri;
    }

    server {
      listen 443 ssl;
      server_name vaultwarden.local 192.168.2.125;

      ssl_certificate     ${certPem};
      ssl_certificate_key ${keyPem};

      location / {
        proxy_pass http://127.0.0.1:${toString hostPort};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      }
    }
  '';

  vhostScript = pkgs.writeShellScriptBin "vaultwarden-nginx-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-nginx] Writing Vaultwarden nginx vhost"
    mkdir -p "${appsDir}"

    cat > "${vhostFile}" <<'EOF'
${vhost}
EOF
  '';
in
{
  environment.systemPackages = [ vhostScript ];

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-nginx-setup"
    ${vhostScript}/bin/vaultwarden-nginx-setup
  '';
}
