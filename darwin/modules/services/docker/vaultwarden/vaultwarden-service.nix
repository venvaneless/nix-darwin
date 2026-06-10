# /Users/ven/.config/nix/nix-config/darwin/modules/services/docker/vaultwarden/vaultwarden-service.nix
#
# VAULTWARDEN SERVICE (DARWIN ONLY)
# =================================
# - Ensures data dir exists
# - Starts Vaultwarden through Docker Desktop
# - Uses Docker restart policy for container persistence
# - Creates a user LaunchAgent, not a system daemon
# =================================

{ config, pkgs, lib, ... }:

let
  appName = "vaultwarden";

  dataDir      = config.ven.vaultwarden.dataDir or "/Users/ven/.config/containers/vaultwarden";
  hostPort     = config.ven.vaultwarden.hostPort or 8080;
  internalPort = config.ven.vaultwarden.internalPort or 80;
  envVars      = config.ven.vaultwarden.envVars or [];

  containersRoot = "/Users/ven/.config/containers";

  dockerBin = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  envArgs =
    lib.concatStringsSep " "
      (map (v: "-e ${lib.escapeShellArg v}") envVars);

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
    until "${dockerBin}" info >/dev/null 2>&1; do
      sleep 2
    done

    echo ">>> [vaultwarden] Docker engine ready"

    if ! "${dockerBin}" image inspect vaultwarden/server:latest >/dev/null 2>&1; then
      echo ">>> [vaultwarden] Pulling image"
      "${dockerBin}" pull vaultwarden/server:latest
    fi

    if ! "${dockerBin}" ps -a --format '{{.Names}}' | grep -qx "${appName}"; then
      echo ">>> [vaultwarden] Creating container"
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

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> [vaultwarden] Removing old system daemon if present"
    launchctl bootout system/com.ven.vaultwarden 2>/dev/null || true
    rm -f /Library/LaunchDaemons/com.ven.vaultwarden.plist

    echo ">>> [vaultwarden] Ensuring data dir via activation"
    ${ensureDirScript}/bin/ensure-${appName}-data || echo "!!! [vaultwarden] ensure data dir failed"
  '';

  launchd.agents.vaultwarden = {
    serviceConfig = {
      Label = "com.ven.vaultwarden";
      ProgramArguments = [ "${runner}/bin/run-${appName}" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}