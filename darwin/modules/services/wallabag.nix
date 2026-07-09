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
          - ${cfg.dataDir}/data:/var/www/wallabag/data
          - ${cfg.dataDir}/images:/var/www/wallabag/web/assets/images
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "${cfg.dataDir}/data"
    mkdir -p "${cfg.dataDir}/images"

    chmod -R u+rwX,go+rwX "${cfg.dataDir}"

    echo ">>> [${appName}] Waiting for Docker daemon"

    until ${pkgs.docker_29}/bin/docker info >/dev/null 2>&1; do
      sleep 5
    done

    echo ">>> [${appName}] Docker is ready"
    echo ">>> [${appName}] Pulling image"

    ${pkgs.docker-compose}/bin/docker-compose \
      -p ${appName} \
      -f "${composeFile}" \
      pull

    echo ">>> [${appName}] Starting Wallabag"
    echo ">>> [${appName}] URL: ${cfg.domainName}"

    exec ${pkgs.docker-compose}/bin/docker-compose \
      -p ${appName} \
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
      default = "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/my-system/user-data/01-databases-containers/wallabag";
      description = "Persistent Wallabag data directory.";
    };

    domainName = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8989";
      description = "Wallabag public URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.ensureWallabagDataDir.text = lib.mkAfter ''
      echo ">>> [wallabag] Ensuring data directories"
      mkdir -p "${cfg.dataDir}/data"
      mkdir -p "${cfg.dataDir}/images"
      chown -R ven:staff "${cfg.dataDir}" || true
    '';

    launchd.agents.wallabag = {
      serviceConfig = {
        Label = "com.ven.wallabag";
        ProgramArguments = [ "${runner}/bin/run-${appName}" ];

        RunAtLoad = true;

        KeepAlive = {
          SuccessfulExit = false;
        };

        StandardOutPath = "/tmp/com.ven.wallabag.out.log";
        StandardErrorPath = "/tmp/com.ven.wallabag.err.log";
      };
    };
  };
}