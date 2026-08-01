# darwin/services/docker/mkcert.nix
#
# =====================================================================
# MKCERT: GLOBAL SETUP
# 
# - Installs mkcert as a system package.
# - Ensures mkcert CA is installed into:
#       ~/.config/mkcert
# - Fixes ownership so files are owned by "ven".
# - Logs every step during darwin activation.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  # User home directory
  userName = "ven";

  # mkcert CA root directory
  userHome = config.users.users.${userName}.home;

  # mkcert CA root directory for storing rootCA.pem and rootCA-key.pem
  caroot   = "${userHome}/.config/mkcert";

  # Helper script to ensure mkcert CA is installed and ownership is correct
  mkcertScript = pkgs.writeShellScriptBin "mkcert-install" ''

    #!/usr/bin/env bash
    set -euo pipefail

    # Print messages for debugging
    echo ">>> [mkcert] START mkcert-install"
    echo ">>> [mkcert] CAROOT       = ${caroot}"
    echo ">>> [mkcert] mkcert bin   = ${pkgs.mkcert}/bin/mkcert"

    # Ensure CAROOT directory exists
    mkdir -p "${caroot}"

    # Run mkcert -install once if CA is missing
    if [ ! -f "${caroot}/rootCA.pem" ]; then
      # Print message indicating that mkcert -install is being run
      echo ">>> [mkcert] No rootCA.pem found → running mkcert -install"

      # Run mkcert -install with CAROOT set to the specified directory
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install || {

      	# Print error message if mkcert -install fails and exit with status 1
        echo "!!! [mkcert] mkcert -install FAILED"
        exit 1
      }
      echo ">>> [mkcert] mkcert -install completed"
    else
      echo ">>> [mkcert] Existing rootCA.pem found at ${caroot}/rootCA.pem"
    fi

    # Fix ownership so you can inspect / delete certs without sudo
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

  	# Print message indicating that mkcert-install is being run
    echo ">>> Running mkcert-install (global)"

    # Run the mkcert-install script to ensure mkcert CA is installed and ownership is correct
    ${mkcertScript}/bin/mkcert-install || echo "!!! mkcert-install failed (continuing)"
  '';
}
