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
        depends_on:
          - db
          - redis
        ports:
          - "127.0.0.1:${toString cfg.port}:80"
        env_file:
          - ${cfg.dataDir}/wallabag.env
        environment:
          SYMFONY__ENV__DATABASE_DRIVER: pdo_pgsql
          SYMFONY__ENV__DATABASE_HOST: db
          SYMFONY__ENV__DATABASE_PORT: 5432
          SYMFONY__ENV__DATABASE_NAME: wallabag
          SYMFONY__ENV__DATABASE_USER: wallabag
          SYMFONY__ENV__REDIS_HOST: redis
          SYMFONY__ENV__DOMAIN_NAME: ${cfg.domainName}
        volumes:
          - ${cfg.dataDir}/images:/var/www/wallabag/web/assets/images

      db:
        image: postgres:16-alpine
        container_name: wallabag-db
        restart: unless-stopped
        env_file:
          - ${cfg.dataDir}/wallabag.env
        environment:
          POSTGRES_DB: wallabag
          POSTGRES_USER: wallabag
        volumes:
          - ${cfg.dataDir}/postgres:/var/lib/postgresql/data

      redis:
        image: redis:7-alpine
        container_name: wallabag-redis
        restart: unless-stopped
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "${cfg.dataDir}/images"
    mkdir -p "${cfg.dataDir}/postgres"

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

    echo ">>> [${appName}] Starting Wallabag"
    echo ">>> [${appName}] URL: ${cfg.domainName}"

    exec ${pkgs.docker-compose}/bin/docker-compose \
      -f "${composeFile}" \
      up
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
      pkgs.docker-compose
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