# MKCERT: GLOBAL SETUP (DARWIN)
{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;
  caroot   = "${userHome}/.config/mkcert";

  mkcertScript = pkgs.writeShellScriptBin "mkcert-install" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [mkcert] Ensuring mkcert CA is installed"

    CAROOT="${caroot}"

    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found → running mkcert -install"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install
    else
      echo ">>> [mkcert] CA already present"
    fi
  '';
in
{
  environment.systemPackages = [ pkgs.mkcert mkcertScript ];

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running mkcert-install"
    ${mkcertScript}/bin/mkcert-install
  '';
}
