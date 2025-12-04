# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker-all.nix
#
# DOCKER: ALL-IN-ONE MODULE
# ============================================================
# - Installs/controls Docker Desktop (via ./docker.nix)
# - Manages Vaultwarden (container + nginx + certs) via ./vaultwarden.nix
# - Provides mkContainer + containerDefs for future generic containers
# ============================================================

{ config, pkgs, lib, ... }:

let
  # ----- Base paths -----
  containersRoot = "/Users/ven/ven-dots/user-data/containers";
  dockerBin      = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # ----- Name sanitizer -----
  # Converts arbitrary container name to a safe, lowercase folder name.
  cleanName = name:
    let
      lowered = lib.toLower name;

      allowed =
        lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz-";

      chars =
        lib.stringToCharacters lowered;

      kept =
        lib.filter (c: lib.elem c allowed) chars;
    in
      lib.concatStrings kept;

  # ----- Universal container builder -----
  #
  # Container definition shape:
  #   {
  #     name         = "redis";              # required
  #     image        = "redis:latest";       # required
  #     ports        = [ "6379:6379" ];      # optional
  #     extraVolumes = [ "/host:/cont" ];    # optional
  #     extraArgs    = [ "--flag" "value" ]; # optional
  #     runAtLoad    = false;                # optional (default: true)
  #     keepAlive    = false;                # optional (default: true)
  #   }
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
      cName   = cleanName name;
      dataDir = "${containersRoot}/${cName}";

      # Ports: ["6379:6379"] → "-p 6379:6379 -p ..."
      portArgs =
        lib.concatStringsSep " "
          (map (p: "-p ${p}") ports);

      # Volumes:
      #   Always:
      #     /Users/ven/ven-dots/user-data/containers/<clean-name>:/data
      #   Plus any extraVolumes the container defines
      volumeArgs =
        "-v ${dataDir}:/data "
        + lib.concatStringsSep " "
            (map (v: "-v ${v}") extraVolumes);

      # Extra arguments, if any
      args = lib.concatStringsSep " " extraArgs;

      # Script that ensures the data directory exists.
      ensureDirScript = pkgs.writeShellScriptBin "ensure-${cName}-data" ''
        #!/usr/bin/env bash
        set -euo pipefail

        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"
      '';

      # Runner script for this container
      runner = pkgs.writeShellScriptBin "run-${cName}" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Ensure data directory exists
        "${ensureDirScript}/bin/ensure-${cName}-data"

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
      # Ensure data dir exists at activation time (nix-darwin friendly)
      system.activationScripts."ensure-${cName}-data".text = ''
        "${ensureDirScript}/bin/ensure-${cName}-data"
      '';

      # Expose the runner in PATH (nice to have)
      environment.systemPackages = [ runner ];

      # Launchd daemon: auto-start and keep alive (overridable)
      launchd.daemons."docker-${cName}" = {
        serviceConfig = {
          Label            = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}/bin/run-${cName}" ];
          RunAtLoad        = runAtLoad;
          KeepAlive        = keepAlive;
        };
      };
    };

  # ----- Declarative list of universal containers -----
  #
  # Turn containers ON/OFF here by commenting them in/out.
  #
  # Each imported file (e.g. ./redis.nix) must return a simple
  # attribute set with fields:
  #   - name
  #   - image
  #   - ports        (optional)
  #   - extraVolumes (optional)
  #   - extraArgs    (optional)
  #   - runAtLoad    (optional)
  #   - keepAlive    (optional)
  #
  containerDefs = [
    # Example (uncomment when you create these files):
    # (import ./redis.nix)
    # (import ./postgres.nix)
    # (import ./browsertrix.nix)
  ];

  # Build per-container fragments
  containerFragments = map mkContainer containerDefs;

in
  # IMPORTANT:
  # - This file is now a REAL nix-darwin module (has full module header).
  # - We import docker.nix + vaultwarden.nix here so their
  #   system.activationScripts + launchd daemons are actually wired in.
  #
  {
    imports = [
      ./docker.nix
      ./vaultwarden.nix
    ];
  } // lib.mkMerge containerFragments
