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

  dataDir  = config.ven.vaultwarden.dataDir or "/Users/ven/ven-dots/user-data/containers/vaultwarden";
  hostPort = config.ven.vaultwarden.hostPort or 8080;
  internalPort = config.ven.vaultwarden.internalPort or 80;
  envVars  = config.ven.vaultwarden.envVars or [];

  containersRoot = "/Users/ven/ven-dots/user-data/containers";

  dockerBin =
    "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  envArgs =
    lib.concatStringsSep " "
      (map (v: "-e ${v}") envVars);

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

    echo ">>> [vaultwarden] Starting container…"

    "${ensureDirScript}/bin/ensure-${appName}-data"

    if ! command -v "${dockerBin}" >/dev/null 2>&1; then
      echo "!!! [vaultwarden] docker not found at ${dockerBin}"
      exit 1
    fi

    "${dockerBin}" start ${appName} || \
    "${dockerBin}" run -d \
      --name ${appName} \
      -p ${toString hostPort}:${toString internalPort} \
      -v "${dataDir}:/data" \
      ${envArgs} \
      vaultwarden/server:latest
  '';
in
{
  # Ensure data dir exists at activation time
  system.activationScripts.vaultwardenDataDir.text = ''
    "${ensureDirScript}/bin/ensure-${appName}-data"
  '';

  # Expose runner in PATH
  environment.systemPackages = [ runner ];

  # macOS launchd only
  launchd.daemons.vaultwarden = {
    serviceConfig = {
      Label           = "com.ven.vaultwarden";
      ProgramArguments = [ "${runner}/bin/run-${appName}" ];
      RunAtLoad       = true;
      KeepAlive       = true;
    };
  };
}
