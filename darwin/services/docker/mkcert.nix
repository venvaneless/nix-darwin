# darwin/services/docker/mkcert.nix
#
# =====================================================================
# MKCERT: GLOBAL SETUP
# 
# - Installs mkcert as a system package.
# - Ensures mkcert CA is installed into:
#       ~/.config/mkcert
# - Fixes ownership so files are owned by "ven".
#
# Activation output:
# - Silent when the CA already exists and is owned correctly.
# - Logs only when it creates the CA or repairs ownership, and on error.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  # ---- SHARED PATHS ---- #
  # The CA root is shared with the Vaultwarden certificate modules, so
  # it is defined once in the centralized path definitions.
  paths = import ../../../options/paths.nix { };

  # User that must own the generated CA files
  userName = paths.user.name;

  # mkcert CA root directory for storing rootCA.pem and rootCA-key.pem
  caroot   = paths.darwin.home.mkcert;

  # Helper script to ensure mkcert CA is installed and ownership is correct
  mkcertScript = pkgs.writeShellScriptBin "mkcert-install" ''

    #!/usr/bin/env bash
    set -euo pipefail

    # ---- NOTHING TO DO ---- #
    # Both halves of the CA are present and the directory already
    # belongs to the user, so there is no work and nothing to report.
    #
    # ** Ownership is part of the check on purpose. Skipping only on
    # ** file existence would stop repairing a CAROOT that ended up
    # ** owned by root, which is what made it unreadable before.
    if [ -f "${caroot}/rootCA.pem" ] \
      && [ -f "${caroot}/rootCA-key.pem" ] \
      && [ "$(${paths.darwin.system.bin.stat} -f '%Su' "${caroot}" 2>/dev/null || true)" = "${userName}" ]; then
      exit 0
    fi

    # ---- WORK IS NEEDED ---- #
    # From here on every step reports, because something changed.
    echo ">>> [mkcert] CAROOT = ${caroot}"

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

    # Run the mkcert-install script to ensure mkcert CA is installed and ownership is correct.
    # ** The script is silent when there is nothing to do, so no banner
    # ** is printed here either.
    ${mkcertScript}/bin/mkcert-install || echo "!!! mkcert-install failed (continuing)"
  '';
}
