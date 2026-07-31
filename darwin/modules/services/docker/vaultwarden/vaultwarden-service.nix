# /Users/ven/.config/nix/nix-config/darwin/modules/services/docker/vaultwarden/vaultwarden-service.nix
#
# =====================================================================
# VAULTWARDEN SERVICE
# 
# - Ensures data dir exists
# - Starts Vaultwarden through Docker Desktop
# - Uses Docker restart policy for container persistence
# - Creates a user LaunchAgent, not a system daemon
# =====================================================================

{ config, pkgs, lib, ... }:

let
  appName = "vaultwarden";

  dataDir      = config.ven.vaultwarden.dataDir or "/Users/ven/.config/containers/vaultwarden";
  # Host port for Vaultwarden container (nginx will talk to this)
  hostPort     = config.ven.vaultwarden.hostPort or 8080;
  
  # Internal container port for Vaultwarden (default HTTP)
  internalPort = config.ven.vaultwarden.internalPort or 80;

  # Environment variables for Vaultwarden container
  envVars      = config.ven.vaultwarden.envVars or [];

  # User-specific directory for container data
  containersRoot = "/Users/ven/.config/containers";

  # Docker binary path for Docker Desktop on macOS
  dockerBin = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # Concatenate environment variables into Docker run arguments
  envArgs =
    lib.concatStringsSep " "
      (map (v: "-e ${lib.escapeShellArg v}") envVars);

  # Ensure the data directory exists and has the correct permissions
  ensureDirScript = pkgs.writeShellScriptBin "ensure-${appName}-data" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Ensuring data directory: ${dataDir}"
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"
    chmod 700 "${dataDir}"
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Starting Vaultwarden runner"

    "${ensureDirScript}/bin/ensure-${appName}-data"

    if [ ! -x "${dockerBin}" ]; then
      echo "!!! [vaultwarden] docker not found at ${dockerBin}"
      exit 1
    fi

    echo ">>> [vaultwarden] Waiting for Docker engine..."
    # Check if Docker is ready, retrying up to 60 times with a 2-second interval
    docker_attempt=1

    # Limit the number of attempts to avoid infinite loops
    docker_attempt_limit=60

    # Wait for Docker to become ready
    until "${dockerBin}" info >/dev/null 2>&1; do
      if [ "$docker_attempt" -ge "$docker_attempt_limit" ]; then
        echo "!!! [vaultwarden] Docker engine did not become ready"
        exit 1
      fi
      sleep 2
      docker_attempt=$((docker_attempt + 1))
    done

    echo ">>> [vaultwarden] Docker engine ready"

    # Check if the Vaultwarden image is present; if not, pull it
    if ! "${dockerBin}" image inspect vaultwarden/server:latest >/dev/null 2>&1; then
      echo ">>> [vaultwarden] Pulling image"
      "${dockerBin}" pull vaultwarden/server:latest
    fi

    # Check if the container exists; if not, create it. If it exists, update the restart policy.
    if ! "${dockerBin}" ps -a --format '{{.Names}}' | grep -qx "${appName}"; then
      echo ">>> [vaultwarden] Creating container"
      # If the container is absent, recreate it with the specified ports, volumes, and environment variables
      "${dockerBin}" run -d \
        --name ${appName} \
        --restart unless-stopped \
        -p ${toString hostPort}:${toString internalPort} \
        -v "${dataDir}:/data" \
        ${envArgs} \
        vaultwarden/server:latest
    else
      echo ">>> [vaultwarden] Container exists; updating restart policy"
      "${dockerBin}" update --restart unless-stopped ${appName} >/dev/null
    fi

    echo ">>> [vaultwarden] Starting container"
    "${dockerBin}" start ${appName} >/dev/null || true

    echo ">>> [vaultwarden] Done"
  '';
in
{
  environment.systemPackages = [
    runner
    ensureDirScript
  ];

  # Stable runner path for launchd.
  environment.etc."ven/services/run-vaultwarden".source =
    "${runner}/bin/run-${appName}";

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> [vaultwarden] Ensuring data dir via activation"
    ${ensureDirScript}/bin/ensure-${appName}-data || echo "!!! [vaultwarden] ensure data dir failed"
  '';

  launchd.agents.vaultwarden = {
    serviceConfig = {
      Label = "com.ven.vaultwarden";
      ProgramArguments = [ "/etc/ven/services/run-vaultwarden" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}