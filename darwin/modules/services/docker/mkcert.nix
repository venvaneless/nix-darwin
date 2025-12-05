# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/mkcert.nix
#
# MKCERT: GLOBAL SETUP
# ====================
# - Installs mkcert as a system package.
# - Provides mkcert-global-setup CLI script.
# - Ensures the local CA is installed under ~/.config/mkcert.
# ====================

{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;
  caroot   = "${userHome}/.config/mkcert";

  mkcertSetup = pkgs.writeShellScriptBin "mkcert-global-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [mkcert] Ensuring mkcert CA is installed"
    CAROOT="${caroot}"

    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found -> running mkcert -install"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install || {
        echo "!!! [mkcert] mkcert -install failed"
        exit 1
      }
    else
      echo ">>> [mkcert] mkcert CA already present at ${caroot}"
    fi
  '';
in
{
  # Install mkcert and the helper script
  environment.systemPackages = [ pkgs.mkcert mkcertSetup ];

  # Run it automatically during activation as well
  system.activationScripts.mkcert-install.text = lib.mkAfter ''
    "${mkcertSetup}/bin/mkcert-global-setup"
  '';
}
