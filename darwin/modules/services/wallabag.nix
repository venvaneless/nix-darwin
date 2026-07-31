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
          - "${toString cfg.port}:80"
        environment:
          SYMFONY__ENV__DOMAIN_NAME: ${cfg.domainName}
        volumes:
          - ${cfg.dataDir}/data:/var/www/wallabag/data
          - ${cfg.dataDir}/images:/var/www/wallabag/web/assets/images
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Docker Desktop credential helpers are not included in launchd's
    # default PATH, so add Docker Desktop's executable directory.
    export PATH="/Applications/Programming/Docker.app/Contents/Resources/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    mkdir -p "${cfg.dataDir}/data"
    mkdir -p "${cfg.dataDir}/images"

    chmod -R u+rwX,go+rwX "${cfg.dataDir}"

    echo ">>> [${appName}] Waiting for Docker daemon"

    docker_attempt=1
    docker_attempt_limit=60

    until ${pkgs.docker_29}/bin/docker info >/dev/null 2>&1; do
      if [ "$docker_attempt" -ge "$docker_attempt_limit" ]; then
        echo "!!! [${appName}] Docker daemon did not become ready"
        exit 1
      fi

      sleep 2
      docker_attempt=$((docker_attempt + 1))
    done

    echo ">>> [${appName}] Docker is ready"
    echo ">>> [${appName}] Starting Wallabag"
    echo ">>> [${appName}] URL: ${cfg.domainName}"

    ${pkgs.docker-compose}/bin/docker-compose \
      -p "${appName}" \
      -f "${composeFile}" \
      up \
      -d \
      --remove-orphans

    echo ">>> [${appName}] Wallabag is running"
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
    environment.systemPackages = [ runner ];

    # Stable runner path for launchd.
    environment.etc."ven/services/run-wallabag".source =
      "${runner}/bin/run-${appName}";

    system.activationScripts.ensureWallabagDataDir.text = lib.mkAfter ''
      echo ">>> [wallabag] Ensuring data directories"
      mkdir -p "${cfg.dataDir}/data"
      mkdir -p "${cfg.dataDir}/images"
      chown -R ven:staff "${cfg.dataDir}" || true
    '';

    launchd.agents.wallabag = {
      serviceConfig = {
        Label = "com.ven.wallabag";
        ProgramArguments = [ "/etc/ven/services/run-wallabag" ];

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