# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker.nix
#
# DOCKER (DARWIN ONLY)
# ============================
# - Installs Docker Desktop via Homebrew cask
# - Ensures /Applications/Programming exists
# - Creates a launchd daemon to keep Docker Desktop running
# ============================

{ config, pkgs, lib, ... }:

{
  # Ensure target Applications directory exists
  system.activationScripts.ensureDockerAppDir.text = lib.mkAfter ''
    echo ">>> [docker] Ensuring /Applications/Programming exists"
    mkdir -p "/Applications/Programming"
  '';

  # Install Docker Desktop via Homebrew
  homebrew.casks = [
    {
      name = "docker";
      args = { appdir = "/Applications/Programming"; };
    }
  ];

  # Launchd daemon: keep Docker Desktop running
  launchd.daemons.docker-desktop = {
    serviceConfig = {
      Label           = "com.ven.docker-desktop";
      ProgramArguments = [
        "/Applications/Programming/Docker.app/Contents/MacOS/Docker"
      ];
      RunAtLoad       = true;
      KeepAlive       = true;
    };
  };
}
