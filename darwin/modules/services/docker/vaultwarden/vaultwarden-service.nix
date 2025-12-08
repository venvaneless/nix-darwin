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

  # Data dir is now system-level, under /var/lib/containers
  dataDir      = config.ven.vaultwarden.dataDir or "/var/lib/containers/vaultwarden";
  hostPort     = config.ven.vaultwarden.hostPort or 8080;
  internalPort = config.ven.vaultwarden.internalPort or 80;
  envVars      = config.ven.vaultwarden.envVars or [];

  dockerBin =
    "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  envArgs =
    lib.concatStringsSep " "
      (map (v: "-e ${v}") envVars);

  # This script runs *as the user*, not root.
  # It CANNOT safely chown/chmod.
  ensureDirScript = pkgs.writeShellScriptBin "ensure-${appName}-data" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Ensuring data directory exists: ${dataDir}"
    mkdir -p "${dataDir}"
  '';

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Starting container..."

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
  # ROOT-LEVEL PERMISSIONS — this MUST be root (activation)
  system.activationScripts."vaultwarden-data-perms".text = lib.mkAfter ''
    echo ">>> [vaultwarden] Activation: preparing data dir (root)"
    mkdir -p "${dataDir}"
    chown root:containers "${dataDir}"
    chmod 770 "${dataDir}"
  '';

  # Expose runner in PATH
  environment.systemPackages = [ runner ensureDirScript ];

  # macOS launchd daemon
  launchd.daemons.vaultwarden = {
    serviceConfig = {
      Label            = "com.ven.vaultwarden";
      ProgramArguments = [ "${runner}/bin/run-${appName}" ];
      RunAtLoad        = true;
      KeepAlive        = true;
    };
  };
}
