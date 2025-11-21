# /Users/ven/dotfiles/nix/darwin/modules/services/docker/docker-all.nix
#
# DOCKER: ALL-IN-ONE MODULE
# ============================================================
# Imports:
#   - docker.nix (installs Docker Desktop)
#   - vaultwarden.nix (custom Vaultwarden container)
#   - vaultwarden-nginx.nix (reverse proxy for Vaultwarden)
#
# Provides:
#   - mkContainer: template for universal containers
#   - Declarative storage under:
#         /Users/ven/dotfiles/containers/<clean-name>
#   - launchd auto-start + KeepAlive for all containers
#   - Runner scripts using: docker start || docker run -d
#   - services.dockerContainers list to enable/disable containers
#
# Vaultwarden stays separate and untouched.
# ============================================================

{ config, pkgs, lib, ... }:

let
  # ----- Paths -----
  containersRoot = "/Users/ven/dotfiles/containers";

  # Docker CLI (stable universal macOS path)
  dockerBin = "/usr/local/bin/docker";

  # ------------------------------------------------------------
  # Sanitize container names
  # ------------------------------------------------------------
  cleanName = name:
    lib.replaceStrings
      [ " " "-" "_" "/" ":" "." "," "'" "\"" "(" ")" "[" "]" "{" "}" "@" "#" "$" "%" "^" "&" "*" "+" "=" ]
      [ ""  ""  ""  ""  ""  ""  ""  ""  ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ]
      (lib.toLower name);

  # ------------------------------------------------------------
  # mkContainer: Defines metadata for one universal container
  # ------------------------------------------------------------
  mkContainer = { name, image, ports ? [], extraVolumes ? [], extraArgs ? [] }:
    let
      cName   = cleanName name;
      dataDir = "${containersRoot}/${cName}";

      # Port mapping e.g. "6379:6379"
      portArgs =
        lib.concatStringsSep " "
          (map (p: "-p ${p}") ports);

      # Volume mapping: OPTION A = 1 (map folder directly)
      volumeArgs =
        "-v ${dataDir}:/data "
        + lib.concatStringsSep " "
            (map (v: "-v ${v}") extraVolumes);

      # Extra flags
      args = lib.concatStringsSep " " extraArgs;

      # Create the unified runner script
      runner = pkgs.writeShellScript "run-${cName}" ''
        #!/bin/bash
        set -euo pipefail

        # Auto-create data directory if missing
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"

        # Try starting container OR create it
        ${dockerBin} start ${cName} || \
        ${dockerBin} run -d \
          --name ${cName} \
          ${portArgs} \
          ${volumeArgs} \
          ${args} \
          ${image}
      '';
    in
    {
      # ----- Activation: ensure folder exists -----
      system.activationScripts."ensure-${cName}-data".text = ''
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"
      '';

      # ----- Launchd: keep container alive -----
      launchd.daemons."docker-${cName}" = {
        serviceConfig = {
          Label = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };

in
{
  # ============================================================
  # Imports: Docker Desktop + Vaultwarden + Vaultwarden NGINX
  # ============================================================
  imports = [
    ./docker.nix
    ./vaultwarden.nix
    ./vaultwarden-nginx.nix
  ];

  # ============================================================
  # Declarative container list (you control ON/OFF here)
  # ============================================================
  options = {
    services.dockerContainers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = ''
        List of universal container metadata:
        
        services.dockerContainers = [
          (import ./redis.nix)
          (import ./postgres.nix)
        ];
      '';
    };
  };

  # ============================================================
  # Apply mkContainer to every entry in services.dockerContainers
  # ============================================================
  config = let
    universal = map mkContainer config.services.dockerContainers;
  in
    lib.mkMerge universal;
}
