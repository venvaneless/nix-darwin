# /Users/ven/.config/nix/nix-config/darwin/modules/services/docker/mkcert.nix
#
# MKCERT: GLOBAL SETUP (DARWIN)
# ============================================================
# - Installs mkcert as a system package.
# - Ensures mkcert CA is installed into:
#       ~/.config/mkcert
# - Fixes ownership so files are owned by "ven".
# - Logs every step during darwin activation.
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;
  caroot   = "${userHome}/.config/mkcert";

  mkcertScript = pkgs.writeShellScriptBin "mkcert-install" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [mkcert] START mkcert-install"
    echo ">>> [mkcert] CAROOT       = ${caroot}"
    echo ">>> [mkcert] mkcert bin   = ${pkgs.mkcert}/bin/mkcert"

    # --- Ensure CAROOT directory exists ---
    mkdir -p "${caroot}"

    # --- Run mkcert -install once if CA is missing ---
    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found → running mkcert -install"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install || {
        echo "!!! [mkcert] mkcert -install FAILED"
        exit 1
      }
      echo ">>> [mkcert] mkcert -install completed"
    else
      echo ">>> [mkcert] Existing rootCA.pem found at ${caroot}/rootCA.pem"
    fi

    # --- Fix ownership so you can inspect / delete certs without sudo ---
    echo ">>> [mkcert] Fixing ownership of CAROOT → ${userName}:staff"
    chown -R "${userName}:staff" "${caroot}" || {
      echo "!!! [mkcert] chown failed (continuing anyway)"
    }

    echo ">>> [mkcert] DONE mkcert-install"
  '';
in
{
  # Install mkcert CLI and helper script
  environment.systemPackages = [ pkgs.mkcert mkcertScript ];

  # Run mkcert-install on every darwin activation
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running mkcert-install (global)"
    ${mkcertScript}/bin/mkcert-install || echo "!!! mkcert-install failed (continuing)"
  '';
}
