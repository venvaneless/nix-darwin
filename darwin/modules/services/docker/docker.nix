# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker.nix
#
# DOCKER: DARWIN SERVICE + UNIVERSAL CONTAINERS
# ============================================================

{ config, pkgs, lib, ... }:

let
  # ----- Base paths -----
  containersRoot = "/Users/ven/ven-dots/user-data/containers";
  dockerBin      = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  dockerAppDir  = "/Applications/Programming";
  dockerAppPath = "${dockerAppDir}/Docker.app/Contents/MacOS/Docker";

  # ----- Container list comes from docker-all.nix -----
  containerDefs = config.containerDefs;

  # ----- cleanName -----
  cleanName = name:
    let
      lowered = lib.toLower name;
      allowed = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz-";
      chars   = lib.stringToCharacters lowered;
      kept    = lib.filter (c: lib.elem c allowed) chars;
    in lib.concatStrings kept;

  # ----- mkContainer -----
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
      portArgs = lib.concatStringsSep " " (map (p: "-p ${p}") ports);
      volumeArgs =
        "-v ${dataDir}:/data "
        + lib.concatStringsSep " " (map (v: "-v ${v}") extraVolumes);
      args = lib.concatStringsSep " " extraArgs;

      ensureDirScript = pkgs.writeShellScriptBin "ensure-${cName}-data" ''
        #!/usr/bin/env bash
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"
      '';

      runner = pkgs.writeShellScriptBin "run-${cName}" ''
        #!/usr/bin/env bash
        set -euo pipefail
        "${ensureDirScript}/bin/ensure-${cName}-data"
        "${dockerBin}" start ${cName} || \
        "${dockerBin}" run -d --name ${cName} ${portArgs} ${volumeArgs} ${args} ${image}
      '';
    in
    {
      system.activationScripts."ensure-${cName}-data".text =
        ''"${ensureDirScript}/bin/ensure-${cName}-data"'';

      environment.systemPackages = [ runner ];

      launchd.daemons."docker-${cName}" = {
        serviceConfig = {
          Label = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}/bin/run-${cName}" ];
          RunAtLoad = runAtLoad;
          KeepAlive = keepAlive;
        };
      };
    };

  containerFragments = map mkContainer containerDefs;

in
{
  # ----- Docker Desktop installation -----
  system.activationScripts.ensureDockerAppDir.text =
    ''mkdir -p "${dockerAppDir}"'';

  homebrew.casks = [
    { name = "docker"; args = { appdir = dockerAppDir; }; }
  ];

  launchd.daemons.docker-desktop = {
    serviceConfig = {
      Label = "com.ven.docker-desktop";
      ProgramArguments = [ dockerAppPath ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

} // lib.mkMerge containerFragments
