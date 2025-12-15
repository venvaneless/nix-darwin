# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/mas.nix
#
# MAC APP STORE: INSTALL APPS
# ============================================================
# Installs Mac App Store applications using the `mas` CLI.
#
# NOTES:
# - nix-darwin does NOT provide `services.mas`
# - App Store login must be done manually once
# - Apps are installed declaratively via activation script
# ============================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # DECLARED MAS APPLICATIONS
  # ------------------------------------------------------------
  # Tree-style definition for clarity and reuse
  # ------------------------------------------------------------
  masApps = {
    SnippetsLab = 1006087419;
  };

  # ------------------------------------------------------------
  # MAS INSTALL SCRIPT
  # ------------------------------------------------------------
  installMasApps = pkgs.writeShellScriptBin "install-mas-apps" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[mas] Checking App Store login status"

    if ! mas account >/dev/null 2>&1; then
      echo "[mas] ERROR: Not signed into the Mac App Store"
      echo "[mas] Sign in once manually, then re-run darwin-rebuild"
      exit 0
    fi

    echo "[mas] Installing declared Mac App Store applications"

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: id: ''
        if mas list | awk '{print $1}' | grep -q "^${toString id}$"; then
          echo "[mas] ${name} already installed"
        else
          echo "[mas] Installing ${name}"
          mas install ${toString id}
        fi
      '')
      masApps
    )}

    echo "[mas] Mac App Store apps processed"
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
