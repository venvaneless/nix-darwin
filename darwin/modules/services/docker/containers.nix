# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/containers.nix
#
# DOCKER CONTAINERS (DARWIN-ONLY HELPER)
# ======================================
# - Provides mkContainer helper for future use.
# - Only defines launchd services (no systemd here).
# ======================================

{ config, pkgs, lib, ... }:

let
  containersRoot = "/Users/ven/ven-dots/user-data/containers";

  dockerBin =
    "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  mkContainer =
    { name
    , image
    , ports ? []
    , extraVolumes ? []
    , extraArgs ? []
    , runAtLoad ? true
    , keepAlive ? true
    }:
    let
      cName   = lib.toLower name;
      dataDir = "${containersRoot}/${cName}";

      portArgs =
        lib.concatStringsSep " "
          (map (p: "-p ${p}") ports);

      volumeArgs =
        "-v ${dataDir}:/data "
        + lib.concatStringsSep " "
            (map (v: "-v ${v}") extraVolumes);

      args = lib.concatStringsSep " " extraArgs;

      ensureDirScript = pkgs.writeShellScriptBin "ensure-${cName}-data" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo ">>> [container:${cName}] Ensuring data dir: ${dataDir}"
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"
      '';

      runner = pkgs.writeShellScriptBin "run-${cName}" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo ">>> [container:${cName}] Starting…"
        "${ensureDirScript}/bin/ensure-${cName}-data"

        if ! command -v "${dockerBin}" >/dev/null 2>&1; then
          echo "!!! [container:${cName}] docker not found at ${dockerBin}"
          exit 1
        fi

        "${dockerBin}" start ${cName} || \
        "${dockerBin}" run -d \
          --name ${cName} \
          ${portArgs} \
          ${volumeArgs} \
          ${args} \
          ${image}
      '';
    in
    {
      # Ensure data dir exists at activation time
      system.activationScripts."ensure-${cName}-data".text = ''
        "${ensureDirScript}/bin/ensure-${cName}-data"
      '';

      # Expose runner
      environment.systemPackages = [ runner ];

      # launchd only (Darwin)
      launchd.daemons."docker-${cName}" = {
        serviceConfig = {
          Label           = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}/bin/run-${cName}" ];
          RunAtLoad       = runAtLoad;
          KeepAlive       = keepAlive;
        };
      };
    };

in
{
  options.ven.docker.mkContainer = lib.mkOption {
    type = lib.types.anything;
    default = mkContainer;
    description = "Helper function to declare Docker containers (Darwin only).";
  };

  config = { };
}
