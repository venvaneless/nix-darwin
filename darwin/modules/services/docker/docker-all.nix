# /Users/ven/dotfiles/nix/darwin/modules/services/docker/docker-all.nix
#
# DOCKER: ALL-IN-ONE MODULE
# ============================================================
# Imports:
#   - docker.nix (installs Docker Desktop & keeps it running)
#   - vaultwarden.nix (custom Vaultwarden container)
#   - vaultwarden-nginx.nix (reverse proxy for Vaultwarden)
#
# Provides:
#   - mkContainer: builds per-container activation + launchd jobs
#   - Declarative storage under:
#         /Users/ven/dotfiles/containers/<clean-name>
#   - launchd auto-start + KeepAlive for all universal containers
#   - Runner scripts using: docker start || docker run -d
#
# IMPORTANT:
#   - Vaultwarden remains fully separate and is NOT managed
#     by mkContainer.
#   - You enable/disable universal containers by editing the
#     `containerDefs` list below.
# ============================================================

{ pkgs, lib, ... }:

let
  # ----- Base paths -----
  containersRoot = "/Users/ven/dotfiles/containers";
  dockerBin      = "/usr/local/bin/docker";

  # ----- Name sanitizer -----
  # Converts arbitrary container name to a safe, lowercase folder name.
  cleanName = name:
    lib.replaceStrings
      [ " " "-" "_" "/" ":" "." "," "'" "\"" "(" ")" "[" "]" "{" "}" "@" "#" "$" "%" "^" "&" "*" "+" "=" ]
      [ ""  ""  ""  ""  ""  ""  ""  ""  ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ""   ]
      (lib.toLower name);

  # ----- Universal container builder -----
  # Takes a single container definition and produces Nix config
  # fragments for:
  #   - system.activationScripts.ensure-<name>-data
  #   - launchd.daemons.docker-<name>
  #
  # Container definition shape:
  #   {
  #     name         = "redis";
  #     image        = "redis:latest";
  #     ports        = [ "6379:6379" ];
  #     extraVolumes = [ "/host/path:/container/path" ];
  #     extraArgs    = [ "--some-flag" "value" ];
  #   }
  mkContainer = { name, image, ports ? [], extraVolumes ? [], extraArgs ? [] }:
    let
      cName   = cleanName name;
      dataDir = "${containersRoot}/${cName}";

      # Ports: ["6379:6379"] → "-p 6379:6379 -p ..."
      portArgs =
        lib.concatStringsSep " "
          (map (p: "-p ${p}") ports);

      # Volumes:
      #   A = 1 → /Users/ven/dotfiles/containers/<name>:/data
      volumeArgs =
        "-v ${dataDir}:/data "
        + lib.concatStringsSep " "
            (map (v: "-v ${v}") extraVolumes);

      # Extra arguments, if any
      args = lib.concatStringsSep " " extraArgs;

      # Runner script for this container
      runner = pkgs.writeShellScript "run-${cName}" ''
        #!/bin/bash
        set -euo pipefail

        # Ensure data directory exists
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"

        # Start existing container OR create it
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
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"
      '';

      # Launchd daemon: auto-start and keep alive
      launchd.daemons."docker-${cName}" = {
        serviceConfig = {
          Label = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };

  # ----- Declarative list of universal containers -----
  #
  # Turn containers ON/OFF here by commenting them in/out.
  #
  # Each imported file (e.g. ./redis.nix) must return a simple
  # attribute set with fields:
  #   - name         (string, required)
  #   - image        (string, required)
  #   - ports        (optional list of strings)
  #   - extraVolumes (optional list of strings)
  #   - extraArgs    (optional list of strings)
  #
  containerDefs = [
    # Example (uncomment when you create these files):
    # (import ./redis.nix)
    # (import ./postgres.nix)
  ];

  # Build per-container fragments
  containerFragments = map mkContainer containerDefs;

in
  # Merge:
  #  - imports (Docker Desktop + Vaultwarden + NGINX)
  #  - one fragment per universal container
  ({
    imports = [
      ./docker.nix
      ./vaultwarden.nix
      ./vaultwarden-nginx.nix
    ];
  } // lib.mkMerge containerFragments)
