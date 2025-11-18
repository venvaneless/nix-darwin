# /Users/ven/dotfiles/nix/darwin/modules/services/vaultwarden.nix
#
# VAULTWARDEN: DARWIN CONTAINER
# ============================================================
# Runs Vaultwarden as a Docker container on macOS using Docker Desktop.
# Data is stored in:
#   /Users/ven/dotfiles/containers/vaultwarden
#
# The launchd job:
#   - runs at boot
#   - tries `docker start vaultwarden`
#   - if the container does not exist, it runs `docker run -d ...`
#   - is kept alive by launchd (retries if Docker isn't ready yet)
# ============================================================

{ config, pkgs, lib, ... }:

let
  # ----- Paths -----
  containersRoot = "/Users/ven/dotfiles/containers";
  appName        = "vaultwarden";
  dataDir        = "${containersRoot}/${appName}";

  # Docker CLI (nix-homebrew default on Apple Silicon)
  dockerBin = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # ----- Environment variables for Vaultwarden -----
  envVars = [
    "-e" "WEBSOCKET_ENABLED=true"
    "-e" "ENABLE_DB_WAL=false"
    "-e" "ROCKET_LIMITS={forms=\"64KiB\"}"
    "-e" "PASSWORD_ITERATIONS=100000"
    "-e" "PASSWORD_HINTS=true"
  ];

  # Convert env list to string
  envString = lib.concatStringsSep " " envVars;

  # ----- Shell command: start or create container -----
  vaultwardenCommand =
    "${dockerBin} start ${appName} || " +
    "${dockerBin} run -d " +
      "--name ${appName} " +
      "-p 8080:80 -p 8222:80 " +
      "-v ${dataDir}:/data " +
      "${envString} " +
      "vaultwarden/server:latest";

in
{
  # ----- Ensure data directory exists -----
  system.activationScripts.vaultwardenDataDir.text = ''
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"
    chmod 700 "${dataDir}"
  '';

  # ----- Launchd daemon -----
  launchd.daemons.vaultwarden = {
    serviceConfig = {
      Label = "com.ven.vaultwarden";

      ProgramArguments = [
        "/bin/sh"
        "-c"
        vaultwardenCommand
      ];

      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
