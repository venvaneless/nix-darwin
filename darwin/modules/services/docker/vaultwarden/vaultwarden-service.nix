# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-service.nix
#
# VAULTWARDEN: SERVICE WIRES
# ==========================
# - Ensures data directory exists.
# - Provides a runner script that:
#     - checks Docker binary
#     - tries `docker start vaultwarden`
#     - falls back to `docker run -d ...`
# - Creates launchd (macOS) and systemd (Linux) units.
# ==========================

{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux  = pkgs.stdenv.isLinux;

  appName  = "vaultwarden";
  dataDir  = config.ven.vaultwarden.dataDir or "/Users/ven/ven-dots/user-data/containers/vaultwarden";
  hostPort = config.ven.vaultwarden.hostPort or 8080;
  internalPort = config.ven.vaultwarden.internalPort or 80;
  envVars  = config.ven.vaultwarden.envVars or [];

  containersRoot = "/Users/ven/ven-dots/user-data/containers";

  dockerBin =
    if isDarwin then
      "/Applications/Programming/Docker.app/Contents/Resources/bin/docker"
    else
      "docker";

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

    # Try to start existing container; if that fails, run a new one
    "${dockerBin}" start ${appName} || \
    "${dockerBin}" run -d \
      --name ${appName} \
      -p ${hostPort}:${internalPort} \
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

  # macOS launchd
  launchd.daemons.vaultwarden = lib.mkIf isDarwin {
    serviceConfig = {
      Label           = "com.ven.vaultwarden";
      ProgramArguments = [ "${runner}/bin/run-${appName}" ];
      RunAtLoad       = true;
      KeepAlive       = true;
    };
  };

  # Linux systemd
  systemd.services.vaultwarden = lib.mkIf isLinux {
    description = "Vaultwarden Docker container";
    wantedBy    = [ "multi-user.target" ];
    serviceConfig = {
      Type      = "simple";
      ExecStart = "${runner}/bin/run-${appName}";
      Restart   = "always";
    };
  };
}
