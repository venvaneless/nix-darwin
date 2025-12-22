# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-service.nix
#
# VAULTWARDEN SERVICE (DARWIN ONLY)
# =================================
# - Ensures data dir exists
# - Provides run-vaultwarden helper
# - Creates launchd daemon to start/keep container running
# =================================

{ config, pkgs, lib, ... }:

let
  appName  = "vaultwarden";

  dataDir      = config.ven.vaultwarden.dataDir or "/Users/ven/ven-dots/user-data/containers/vaultwarden";
  hostPort     = config.ven.vaultwarden.hostPort or 8080;
  internalPort = config.ven.vaultwarden.internalPort or 80;
  envVars      = config.ven.vaultwarden.envVars or [];

  containersRoot = "/Users/ven/ven-dots/user-data/containers";

  # Docker Desktop binary
  dockerBin =
    "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # Convert env var list → "-e A=B -e C=D ..."
  envArgs =
    lib.concatStringsSep " "
      (map (v: "-e ${v}") envVars);

  # Ensures container data dir exists (same tool used by activation)
  ensureDirScript = pkgs.writeShellScriptBin "ensure-${appName}-data" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Ensuring data directory: ${dataDir}"
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"
    chmod 700 "${dataDir}"
  '';

  # ------------------------------------------------------------
  # RUNNER SCRIPT — Launchd callback that starts the container
  # ------------------------------------------------------------
  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Starting vaultwarden launchd runner"

    # Ensure data directory exists BEFORE docker touches it
    "${ensureDirScript}/bin/ensure-${appName}-data"

    # Make sure the Docker binary exists
    if ! command -v "${dockerBin}" >/dev/null 2>&1; then
      echo "!!! [vaultwarden] docker not found at ${dockerBin}"
      exit 1
    fi

    # ------------------------------------------------------------
    # WAIT FOR DOCKER ENGINE TO BE READY
    # ------------------------------------------------------------
    echo ">>> [vaultwarden] Waiting for Docker engine to become ready..."
    until "${dockerBin}" info >/dev/null 2>&1; do
      echo ">>> [vaultwarden] Docker not ready yet, retrying in 2s..."
      sleep 2
    done
    echo ">>> [vaultwarden] Docker engine is ready"

    # ------------------------------------------------------------
    # Ensure Vaultwarden image exists
    # ------------------------------------------------------------
    echo ">>> [vaultwarden] Checking if Vaultwarden image exists"
    if ! "${dockerBin}" image inspect vaultwarden/server:latest >/dev/null 2>&1; then
      echo ">>> [vaultwarden] Image missing; pulling..."
      "${dockerBin}" pull vaultwarden/server:latest
    else
      echo ">>> [vaultwarden] Image exists"
    fi

    # ------------------------------------------------------------
    # Ensure container exists
    # ------------------------------------------------------------
    echo ">>> [vaultwarden] Checking if container '${appName}' exists"
    if ! "${dockerBin}" ps -a --format '{{.Names}}' | grep -qx "${appName}"; then
      echo ">>> [vaultwarden] Container missing; creating..."
      "${dockerBin}" run -d \
        --name ${appName} \
        -p ${toString hostPort}:${toString internalPort} \
        -v "${dataDir}:/data" \
        ${envArgs} \
        vaultwarden/server:latest
    else
      echo ">>> [vaultwarden] Container exists"
    fi

    # ------------------------------------------------------------
    # Start container
    # ------------------------------------------------------------
    echo ">>> [vaultwarden] Starting container '${appName}'"
    "${dockerBin}" start ${appName} || true
  '';
in
{
  # ------------------------------------------------------------
  # ACTIVATION HOOK — ensures data dir exists on rebuilds
  # ------------------------------------------------------------
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> [vaultwarden] Ensuring data dir via activation"
    ${ensureDirScript}/bin/ensure-${appName}-data || echo "!!! [vaultwarden] ensure data dir failed (continuing)"
  '';

  # Make runner & directory tool available in PATH
  environment.systemPackages = [ runner ensureDirScript ];

  # Stable wrapper path for launchd (avoids /nix/store path churn)
  environment.etc."ven/services/run-vaultwarden".source =
    "${runner}/bin/run-${appName}";

  # ------------------------------------------------------------
  # LAUNCHD SERVICE — auto-start vaultwarden on boot
  # ------------------------------------------------------------
  launchd.daemons.vaultwarden = {
    serviceConfig = {
      Label            = "com.ven.vaultwarden";
      ProgramArguments = [ "/etc/ven/services/run-vaultwarden" ];
      RunAtLoad        = true;
      KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ThrottleInterval = 10;  # <<< FIXED
    };
  };
}
