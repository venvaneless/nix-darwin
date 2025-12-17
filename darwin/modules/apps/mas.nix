# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/mas.nix
#
# MAC APP STORE APPLICATIONS (MAS)
# ============================================================
# Declarative installation of Mac App Store applications
# using the `mas` CLI.
#
# IMPORTANT:
# - Activation scripts run as root
# - MAS installs apps per GUI user
# - Therefore MAS MUST be executed as the primary user
# ============================================================

{ lib, pkgs, config, ... }:

let
  primaryUser = config.system.primaryUser;

  # ------------------------------------------------------------
  # DECLARED MAC APP STORE APPLICATIONS
  # ------------------------------------------------------------
  masApps = {
    SnippetsLab = 1006087419;
  };

  # ------------------------------------------------------------
  # MAS INSTALLATION SCRIPT
  # ------------------------------------------------------------
  installMasApps = pkgs.writeShellScriptBin "install-mas-apps" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[mas] Running MAS installs as user: ${primaryUser}"

    run_as_user() {
      sudo -u "${primaryUser}" "$@"
    }

    install_app() {
      local name="$1"
      local id="$2"
      local app_path="/Applications/$name.app"

      if [ -d "$app_path" ]; then
        echo "[mas] $name already installed"
        return
      fi

      echo "[mas] Installing $name (id: $id)"

      if ! run_as_user mas install "$id"; then
        echo "[mas] ERROR: Failed to install $name"
        echo "[mas] Possible causes:"
        echo "      - ${primaryUser} is not signed into App Store"
        echo "      - App Store GUI session needs refresh"
        echo "      - App Store backend issue"
        exit 0
      fi
    }

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: id: ''
        install_app "${name}" "${toString id}"
      '')
      masApps
    )}

    echo "[mas] Mac App Store applications processed"
  '';
in
{
  # ------------------------------------------------------------
  # MAS CLI
  # ------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    mas
  ];

  # ------------------------------------------------------------
  # ACTIVATION
  # ------------------------------------------------------------
  system.activationScripts.masApps.text = ''
    echo "[nix-darwin] Ensuring Mac App Store applications"
    ${installMasApps}/bin/install-mas-apps
  '';
}
