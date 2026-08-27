# darwin/services/docker/karakeep.nix
#
# KARAKEEP
# =====================================================================
# - Runs the Karakeep web app, Chromium fetcher, and Meilisearch stack.
# - Keeps each writable service directory on the host.
# - Reads authentication and search secrets from a user-owned env file.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  cfg = config.services.karakeep;

  appName = "karakeep";

  # ---- SHARED PATHS ---- #
  # Persistent data directory, secrets file, and launchd log location
  # come from the centralized path definitions.
  paths = import ../../../options/paths.nix { };

  dockerBin = "${pkgs.docker}/bin/docker";
  dockerComposeBin = "${pkgs.docker-compose}/bin/docker-compose";

  composeFile = pkgs.writeText "${appName}-compose.yml" ''
    services:
      web:
        image: ${cfg.image}
        container_name: ${appName}
        restart: unless-stopped
        depends_on:
          - chrome
          - meilisearch
        ports:
          - "127.0.0.1:${toString cfg.port}:3000"
        volumes:
          - ${cfg.dataDir}/data:/data
        environment:
          BROWSER_WEB_URL: "http://chrome:9222"
          DATA_DIR: "/data"
          CRAWLER_FULL_PAGE_ARCHIVE: "true"
          MEILI_ADDR: "http://meilisearch:7700"
          MEILI_MASTER_KEY: "''${MEILI_MASTER_KEY:?Set MEILI_MASTER_KEY in the Karakeep env file}"
          NEXTAUTH_SECRET: "''${NEXTAUTH_SECRET:?Set NEXTAUTH_SECRET in the Karakeep env file}"
          NEXTAUTH_URL: "''${NEXTAUTH_URL:?Set NEXTAUTH_URL in the Karakeep env file}"
      chrome:
        image: ${cfg.chromeImage}
        container_name: ${appName}-chrome
        restart: unless-stopped
        init: true
        command:
          - --disable-gpu
          - --disable-dev-shm-usage
          - --hide-scrollbars
          - --disable-blink-features=AutomationControlled
          - --window-size=1440,900
      meilisearch:
        image: getmeili/meilisearch:v1.41.0
        container_name: ${appName}-meilisearch
        restart: unless-stopped
        volumes:
          - ${cfg.dataDir}/meilisearch:/meili_data
        environment:
          MEILI_MASTER_KEY: "''${MEILI_MASTER_KEY:?Set MEILI_MASTER_KEY in the Karakeep env file}"
          MEILI_NO_ANALYTICS: "true"
  '';

  dockerWait = ''
    docker_attempt=1
    docker_attempt_limit=60

    until "${dockerBin}" info >/dev/null 2>&1; do
      if [ "$docker_attempt" -ge "$docker_attempt_limit" ]; then
        echo "!!! [${appName}] Docker engine did not become ready"
        exit 1
      fi

      sleep 2
      docker_attempt=$((docker_attempt + 1))
    done
  '';

  ensureEnvironment = ''
    if [ ! -f ${lib.escapeShellArg cfg.envFile} ]; then
      echo "!!! [${appName}] Missing credentials file: ${cfg.envFile}"
      exit 1
    fi
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    set -euo pipefail

    ${ensureEnvironment}
    mkdir -p \
      ${lib.escapeShellArg "${cfg.dataDir}/data"} \
      ${lib.escapeShellArg "${cfg.dataDir}/meilisearch"}
    chmod 700 \
      ${lib.escapeShellArg "${cfg.dataDir}/data"} \
      ${lib.escapeShellArg "${cfg.dataDir}/meilisearch"}

    echo ">>> [${appName}] Waiting for Docker engine"
    ${dockerWait}

    "${dockerComposeBin}" \
      --env-file ${lib.escapeShellArg cfg.envFile} \
      -p ${appName} \
      -f "${composeFile}" \
      up -d
  '';
in
{
  options.services.karakeep = {
    enable = lib.mkEnableOption "Karakeep Docker service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Local host port for Karakeep.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = paths.darwin.docker.data.karakeep;
      description = "Persistent Karakeep application and Meilisearch data directory.";
    };

    envFile = lib.mkOption {
      type = lib.types.str;
      default = paths.darwin.docker.env.karakeep;
      description = "User-owned Karakeep secrets file, kept outside the Nix store.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/karakeep-app/karakeep:0.33.2";
      description = "Pinned Karakeep Docker image.";
    };

    chromeImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/karakeep-app/karakeep-chrome:release";
      description = "Karakeep-supported Chrome image for the configured release channel.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ runner ];

    launchd.agents.${appName} = {
      serviceConfig = {
        Label = "com.ven.${appName}";
        ProgramArguments = [ "${runner}/bin/run-${appName}" ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "${paths.darwin.system.tmp}/com.ven.${appName}.out.log";
        StandardErrorPath = "${paths.darwin.system.tmp}/com.ven.${appName}.err.log";
      };
    };
  };
}
