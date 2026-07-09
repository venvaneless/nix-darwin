# /Users/ven/.config/nix/nix-config/darwin/modules/services/wallabag.nix

{ config, pkgs, lib, ... }:

let
  cfg = config.services.wallabag;

  appName = "wallabag";

  composeFile = pkgs.writeText "wallabag-compose.yml" ''
    services:
      wallabag:
        image: wallabag/wallabag:latest
        container_name: wallabag
        restart: unless-stopped
        ports:
          - "127.0.0.1:${toString cfg.port}:80"
        environment:
          SYMFONY__ENV__DOMAIN_NAME: ${cfg.domainName}
        volumes:
          - wallabag-data:/var/www/wallabag/data
          - wallabag-images:/var/www/wallabag/web/assets/images

    volumes:
      wallabag-data:
      wallabag-images:
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ENV_FILE="${cfg.dataDir}/wallabag.env"

    if [ ! -f "$ENV_FILE" ]; then
      echo ">>> [${appName}] Creating env file: $ENV_FILE"

      DB_PASSWORD="$(${pkgs.openssl}/bin/openssl rand -hex 24)"
      SECRET="$(${pkgs.openssl}/bin/openssl rand -hex 32)"

      cat > "$ENV_FILE" <<EOF
POSTGRES_PASSWORD=$DB_PASSWORD
SYMFONY__ENV__DATABASE_PASSWORD=$DB_PASSWORD
SYMFONY__ENV__SECRET=$SECRET
EOF

      chmod 600 "$ENV_FILE"
    fi

    echo ">>> [${appName}] Waiting for Docker daemon"

    until ${pkgs.docker_29}/bin/docker info >/dev/null 2>&1; do
      sleep 5
    done

    echo ">>> [${appName}] Docker is ready"
    echo ">>> [${appName}] Pulling images"

    ${pkgs.docker-compose}/bin/docker-compose \
      -f "${composeFile}" \
      pull

    echo ">>> [${appName}] Starting Wallabag"
    echo ">>> [${appName}] URL: ${cfg.domainName}"

    exec ${pkgs.docker-compose}/bin/docker-compose \
      -f "${composeFile}" \
      up \
      --force-recreate \
      --remove-orphans
  '';
in
{
  options.services.wallabag = {
    enable = lib.mkEnableOption "Wallabag Docker service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8989;
      description = "Local port for Wallabag.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/Users/ven/.local/share/wallabag";
      description = "Persistent Wallabag data directory.";
    };

    domainName = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8989";
      description = "Wallabag public URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      runner
    ];

    launchd.agents.wallabag = {
      serviceConfig = {
        Label = "com.ven.wallabag";
        ProgramArguments = [ "${runner}/bin/run-${appName}" ];

        RunAtLoad = true;
        KeepAlive = true;

        StandardOutPath = "/tmp/com.ven.wallabag.out.log";
        StandardErrorPath = "/tmp/com.ven.wallabag.err.log";
      };
    };
  };
}