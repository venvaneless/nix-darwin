# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker.nix
#
# DOCKER: CROSS-PLATFORM SETUP
# ============================
# - On macOS: installs Docker Desktop via Homebrew cask and starts it via launchd.
# - On Linux/NixOS: enables the Docker service.
# ============================

{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux  = pkgs.stdenv.isLinux;
in
{
  # DARWIN: Docker Desktop via Homebrew + launchd
  # ---------------------------------------------
  homebrew.casks = lib.mkIf isDarwin ([
    {
      name = "docker";
      args = { appdir = "/Applications/Programming"; };
    }
  ]);

  # Ensure target Applications directory exists on macOS
  system.activationScripts.ensureDockerAppDir.text = lib.mkIf isDarwin ''
    echo ">>> [docker] Ensuring /Applications/Programming exists"
    mkdir -p "/Applications/Programming"
  '';

  # Launchd daemon to keep Docker Desktop running (macOS only)
  launchd.daemons.docker-desktop = lib.mkIf isDarwin {
    serviceConfig = {
      Label = "com.ven.docker-desktop";
      ProgramArguments = [
        "/Applications/Programming/Docker.app/Contents/MacOS/Docker"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # LINUX/NixOS: use systemd Docker service
  # ---------------------------------------
  virtualisation.docker.enable = lib.mkIf isLinux true;
}
