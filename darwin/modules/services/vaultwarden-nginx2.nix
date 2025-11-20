# /Users/ven/dotfiles/nix/darwin/modules/services/vaultwarden-nginx.nix

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

      server {
        listen 80 default_server;
        server_name _;
        return 301 https://vaultwarden.local$request_uri;
      }

      server {
        listen 443 ssl;
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
  system.activationScripts.vaultwardenCert.text =
    let
      mkcert = "${pkgs.mkcert}/bin/mkcert";
    in
    ''
      mkdir -p "${certDir}"

      if [ ! -f /usr/local/bin/vaultwarden-mkcert ]; then
        echo ">> Creating mkcert wrapper..."

        cat > /usr/local/bin/vaultwarden-mkcert <<EOF
#!/bin/bash
${mkcert} \
  -cert-file "${cert}" \
  -key-file "${key}" \
  vaultwarden.local 192.168.2.125
EOF

        chmod +x /usr/local/bin/vaultwarden-mkcert
        echo ">> Run manually: sudo vaultwarden-mkcert"
      fi
    '';

  system.activationScripts.installNginxConf.text = ''
    echo "Installing nginx.conf to /opt/homebrew/etc/nginx/nginx.conf ..."
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
