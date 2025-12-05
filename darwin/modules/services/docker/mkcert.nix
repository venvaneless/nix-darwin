# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/mkcert.nix
#
# MKCERT: GLOBAL SETUP (DARWIN)
# ============================================================
# - Installs mkcert as a system package
# - Ensures mkcert CA is installed into:
#       ~/.config/mkcert
# - Fixes ownership so files are owned by user "ven"
# - Prints clear messages on every activation
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;
  caroot   = "${userHome}/.config/mkcert";

  mkcertScript = pkgs.writeShellScriptBin "mkcert-install" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [mkcert] Ensuring mkcert CA is installed"
    echo ">>> [mkcert]   CAROOT: ${caroot}"

    mkdir -p "${caroot}"

    CAROOT="${caroot}"

    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found → running mkcert -install"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install || {
        echo "!!! [mkcert] mkcert -install failed"
        exit 1
      }
    else
      echo ">>> [mkcert] CA already present at ${caroot}/rootCA.pem"
    fi

    echo ">>> [mkcert] Fixing ownership of CAROOT -> ${userName}:staff"
    chown -R "${userName}:staff" "${caroot}" || echo "!!! [mkcert] chown failed (continuing)"
  '';
in
{
  # mkcert CLI + helper script in PATH
  environment.systemPackages = [ pkgs.mkcert mkcertScript ];

  # Always run mkcert-install via extraActivation (the one we KNOW works)
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running mkcert-install (global)"
    ${mkcertScript}/bin/mkcert-install || echo "!!! mkcert-install failed (continuing)"
  '';
}
