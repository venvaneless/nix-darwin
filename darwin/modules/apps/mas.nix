# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/mas.nix
#
# MAC APP STORE APPLICATIONS (MAS)
# ============================================================
# Declarative installation of Mac App Store applications
# using the `mas` CLI.
#
# IMPORTANT:
# - `mas account` is NOT supported in recent versions
# - App Store login must be done manually once (GUI)
# - Free apps STILL require a signed-in App Store session
#
# This module:
# - Declares MAS apps in a single tree
# - Installs them idempotently
# - Uses real filesystem checks instead of mas metadata
# ============================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # DECLARED MAC APP STORE APPLICATIONS
  # ------------------------------------------------------------
  # Key   = App bundle name (without .app)
  # Value = App Store numeric ID
  #
  # To add apps:
  #   1. Find ID via: mas search <name>
  #   2. Add entry below
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

    echo "[mas] Processing Mac App Store applications"

    install_app() {
      local name="$1"
      local id="$2"
      local app_path="/Applications/$name.app"

      if [ -d "$app_path" ]; then
        echo "[mas] $name already installed"
        return
      fi

      echo "[mas] Installing $name (id: $id)"

      if ! mas install "$id"; then
        echo "[mas] ERROR: Failed to install $name"
        echo "[mas] Possible causes:"
        echo "      - Not signed into App Store"
        echo "      - App Store GUI session needs refresh"
        echo "      - App Store backend issue"
        echo ""
        echo "[mas] Fix:"
        echo "      1. Open App Store.app"
        echo "      2. Sign in"
        echo "      3. Close App Store"
        echo "      4. Re-run darwin-rebuild"
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
