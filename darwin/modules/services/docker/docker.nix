# /Users/ven/.config/nix/nix-config/darwin/modules/services/docker/docker.nix
# 
# =====================================================================
# DOCKER
# 
# - Installs Docker Desktop via Homebrew cask
# - Ensures /Applications/Programming exists
# - Starts Docker Desktop as a user LaunchAgent
# =====================================================================

{ pkgs, lib, ... }:

{
  system.activationScripts.ensureDockerAppDir.text = lib.mkAfter ''
    echo ">>> [docker] Ensuring /Applications/Programming exists"
    mkdir -p "/Applications/Programming"
  '';

  homebrew.casks = [
    {
      name = "docker-desktop";
      args = { appdir = "/Applications/Programming"; };
    }
  ];

  launchd.agents.docker-desktop = {
    serviceConfig = {
      Label = "com.ven.docker-desktop";
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "/Applications/Programming/Docker.app"
      ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}