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
  # Activation script to ensure /Applications/Programming exists before Docker Desktop is installed
  system.activationScripts.ensureDockerAppDir.text = lib.mkAfter ''
    echo ">>> [docker] Ensuring /Applications/Programming exists"
    mkdir -p "/Applications/Programming"
  '';

  # Install Docker Desktop via Homebrew cask with custom appdir
  homebrew.casks = [
    {
      name = "docker-desktop";
      args = { appdir = "/Applications/Programming"; };
    }
  ];

  # Define a LaunchAgent to start Docker Desktop at user login
  launchd.agents.docker-desktop = {
    serviceConfig = {
      # LaunchAgent label for Docker Desktop
      Label = "com.ven.docker-desktop";

      # Path to the Docker Desktop application bundle
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "/Applications/Programming/Docker.app"
      ];
      # Run the LaunchAgent at user login
      RunAtLoad = true;

      # Keep the LaunchAgent alive; if it exits, launchd will restart it
      KeepAlive = false;
    };
  };
}