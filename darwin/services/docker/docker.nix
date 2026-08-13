# darwin/services/docker/docker.nix
# 
# =====================================================================
# DOCKER
# 
# - Installs Docker Desktop via Homebrew cask
# - Ensures /Applications/Programming exists
# - Starts Docker Desktop as a user LaunchAgent
# =====================================================================

{ pkgs, lib, ... }:

let
  # ---- SHARED PATHS ---- #
  # Docker Desktop's install directory, bundle, and the macOS `open`
  # helper all come from the centralized path definitions.
  paths = import ../../../options/paths.nix { };

  appDir = paths.darwin.applications.programming;
in
{
  # Activation script to ensure the Docker Desktop app directory exists before Docker Desktop is installed
  system.activationScripts.ensureDockerAppDir.text = lib.mkAfter ''
    echo ">>> [docker] Ensuring ${appDir} exists"
    mkdir -p "${appDir}"
  '';

  # Install Docker Desktop via Homebrew cask with custom appdir
  homebrew.casks = [
    {
      name = "docker-desktop";
      args = { appdir = appDir; };
    }
  ];

  # Define a LaunchAgent to start Docker Desktop at user login
  launchd.agents.docker-desktop = {
    serviceConfig = {
      # LaunchAgent label for Docker Desktop
      Label = "com.ven.docker-desktop";

      # Path to the Docker Desktop application bundle
      ProgramArguments = [
        paths.darwin.system.bin.open
        "-a"
        paths.darwin.docker.app
      ];
      # Run the LaunchAgent at user login
      RunAtLoad = true;

      # Keep the LaunchAgent alive; if it exits, launchd will restart it
      KeepAlive = false;
    };
  };
}