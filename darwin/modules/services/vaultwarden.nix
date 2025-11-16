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
  dockerBin = "/opt/homebrew/bin/docker";

  # Shell command: start existing container or create it
  vaultwardenCommand =
    "${dockerBin} start ${appName} || " +
    "${dockerBin} run -d " +
      "--name ${appName} " +
      "-p 8080:80 " +
      "-v ${dataDir}:/data " +
      "vaultwarden/server:latest";

in
{
  # ----- Ensure data directory exists -----
  system.activationScripts.vaultwardenDataDir.text = ''
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"
    chmod 700 "${dataDir}"
  '';

  # ----- Launchd daemon: manage Vaultwarden container -----
  # This assumes Docker Desktop is running (managed by docker.nix).
  # If Docker isn't ready at first, KeepAlive causes retries.
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
