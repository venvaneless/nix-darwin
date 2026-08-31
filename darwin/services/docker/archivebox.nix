# darwin/services/docker/archivebox.nix
#
# ARCHIVEBOX
# =====================================================================
# - Runs ArchiveBox locally through Docker Desktop.
# - Keeps the archive collection in a persistent host directory.
# - Reads the initial administrator credentials from a user-owned env file.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  cfg = config.services.archivebox;

  appName = "archivebox";

  # ---- SHARED PATHS ---- #
  # Persistent data directory, credentials file, and launchd log
  # location come from the centralized path definitions.
  paths = import ../../../options/paths.nix { };

  dockerBin = "${pkgs.docker}/bin/docker";
  dockerComposeBin = "${pkgs.docker-compose}/bin/docker-compose";

  composeFile = pkgs.writeText "${appName}-compose.yml" ''
    services:
      archivebox:
        image: ${cfg.image}
        container_name: ${appName}
        restart: unless-stopped
        ports:
          - "127.0.0.1:${toString cfg.port}:8000"
        volumes:
          - ${cfg.dataDir}:/data
        environment:
          ADMIN_USERNAME: "''${ARCHIVEBOX_ADMIN_USERNAME:?Set ARCHIVEBOX_ADMIN_USERNAME in the ArchiveBox env file}"
          ADMIN_PASSWORD: "''${ARCHIVEBOX_ADMIN_PASSWORD:?Set ARCHIVEBOX_ADMIN_PASSWORD in the ArchiveBox env file}"
          BASE_URL: "http://127.0.0.1:${toString cfg.port}"
          PUBLIC_ADD_VIEW: "False"
          SERVER_SECURITY_MODE: "safe-onedomain-nojsreplay"
        shm_size: "1gb"
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
    mkdir -p ${lib.escapeShellArg cfg.dataDir}
    chmod 700 ${lib.escapeShellArg cfg.dataDir}

    echo ">>> [${appName}] Waiting for Docker engine"
    ${dockerWait}

    "${dockerComposeBin}" \
      --env-file ${lib.escapeShellArg cfg.envFile} \
      -p ${appName} \
      -f "${composeFile}" \
      up -d
  '';

  initializer = pkgs.writeShellScriptBin "${appName}-init" ''
    set -euo pipefail

    ${ensureEnvironment}
    mkdir -p ${lib.escapeShellArg cfg.dataDir}
    chmod 700 ${lib.escapeShellArg cfg.dataDir}

    echo ">>> [${appName}] Waiting for Docker engine"
    ${dockerWait}

    exec "${dockerComposeBin}" \
      --env-file ${lib.escapeShellArg cfg.envFile} \
      -p ${appName} \
      -f "${composeFile}" \
      run --rm archivebox init
  '';

  add = pkgs.writeShellScriptBin "${appName}-add" ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      echo "Usage: ${appName}-add <URL> [additional ArchiveBox options]"
      exit 64
    fi

    ${ensureEnvironment}
    echo ">>> [${appName}] Waiting for Docker engine"
    ${dockerWait}

    exec "${dockerComposeBin}" \
      --env-file ${lib.escapeShellArg cfg.envFile} \
      -p ${appName} \
      -f "${composeFile}" \
      exec -T archivebox archivebox add "$@"
  '';

  persona = pkgs.writeShellScriptBin "${appName}-persona" ''
    set -euo pipefail

    ${ensureEnvironment}
    echo ">>> [${appName}] Waiting for Docker engine"
    ${dockerWait}

    exec "${dockerComposeBin}" \
      --env-file ${lib.escapeShellArg cfg.envFile} \
      -p ${appName} \
      -f "${composeFile}" \
      exec -T archivebox archivebox persona "$@"
  '';
in
{
  options.services.archivebox = {
    enable = lib.mkEnableOption "ArchiveBox Docker service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Local host port for ArchiveBox.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = paths.darwin.docker.data.archivebox;
      description = "Persistent ArchiveBox collection directory.";
    };

    envFile = lib.mkOption {
      type = lib.types.str;
      default = paths.darwin.docker.env.archivebox;
      description = "User-owned ArchiveBox credentials file, kept outside the Nix store.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "archivebox/archivebox:dev";
      description = "ArchiveBox Docker image.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ runner initializer add persona ];

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
