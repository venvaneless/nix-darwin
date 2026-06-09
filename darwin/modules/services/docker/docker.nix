# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker.nix
#
# DOCKER (DARWIN ONLY)
# ============================
# - Installs Docker Desktop via Homebrew cask
# - Ensures /Applications/Programming exists
# - Starts Docker Desktop as a user LaunchAgent
# ============================

{ pkgs, lib, ... }:

{
  system.activationScripts.ensureDockerAppDir.text = lib.mkAfter ''
    echo ">>> [docker] Ensuring /Applications/Programming exists"
    mkdir -p "/Applications/Programming"

    echo ">>> [docker] Removing old Docker Desktop system daemon if present"
    launchctl bootout system/com.ven.docker-desktop 2>/dev/null || true
    rm -f /Library/LaunchDaemons/com.ven.docker-desktop.plist
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