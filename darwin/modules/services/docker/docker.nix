# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker.nix
#
# DOCKER: DARWIN SERVICE
# ============================================================
# Installs Docker Desktop via Homebrew into /Applications/Programming
# and configures a launchd daemon to start it automatically.
# Docker is kept alive by launchd; if you really want it off,
# you must disable/unload the launchd job.
# ============================================================

{ config, pkgs, lib, ... }:

let
  dockerAppDir  = "/Applications/Programming";
  dockerAppPath = "${dockerAppDir}/Docker.app/Contents/MacOS/Docker";

in
{
  # ----- Ensure target Applications directory exists -----
  system.activationScripts.ensureDockerAppDir.text = ''
    mkdir -p "${dockerAppDir}"
  '';

  # ----- Install Docker Desktop via Homebrew cask -----
  homebrew.casks = [
    {
      name = "docker";
      args = { appdir = dockerAppDir; };
    }
  ];

  # ----- Launchd daemon: keep Docker Desktop running -----
  # This will:
  #   - start Docker Desktop on boot
  #   - restart it if it crashes or is quit
  # If you want to really shut it down, unload this job.
  launchd.daemons.docker-desktop = {
    serviceConfig = {
      Label = "com.ven.docker-desktop";

      ProgramArguments = [
        dockerAppPath
      ];

      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
