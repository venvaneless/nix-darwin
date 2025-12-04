# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/containers.nix
#
# DOCKER: DECLARATIVE CONTAINERS LIB
# ==================================
# - Provides mkContainer: a helper to define Docker containers declaratively.
# - Works on macOS (launchd) and Linux (systemd).
# - NOT used directly by Vaultwarden yet, but ready for future containers.
# ==================================

{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux  = pkgs.stdenv.isLinux;

  # Default containers/data root for your tools
  containersRoot = "/Users/ven/ven-dots/user-data/containers";

  # Docker binary path per platform
  dockerBin =
    if isDarwin then
      "/Applications/Programming/Docker.app/Contents/Resources/bin/docker"
    else
      "docker";

  # mkContainer: define a container + service for it
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

      # Expose runner in PATH
      environment.systemPackages = [ runner ];

      # launchd (Darwin)
      launchd.daemons."docker-${cName}" = lib.mkIf isDarwin {
        serviceConfig = {
          Label           = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}/bin/run-${cName}" ];
          RunAtLoad       = runAtLoad;
          KeepAlive       = keepAlive;
        };
      };

      # systemd (Linux)
      systemd.services."docker-${cName}" = lib.mkIf isLinux {
        description = "Docker container ${cName}";
        wantedBy    = [ "multi-user.target" ];
        serviceConfig = {
          Type      = "simple";
          ExecStart = "${runner}/bin/run-${cName}";
          Restart   = if keepAlive then "always" else "no";
        };
      };
    };

in
{
  # Export mkContainer via config so other modules can use it later.
  options.ven.docker.mkContainer = lib.mkOption {
    type = lib.types.anything;
    default = mkContainer;
    description = "Helper function to declare Docker containers.";
  };

  config = { };
}
