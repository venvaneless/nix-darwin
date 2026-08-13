# darwin/services/docker/vaultwarden/vaultwarden-mkcert.nix
#
# =====================================================================
# VAULTWARDEN: MKCERT CERTIFICATES
# 
# - Uses mkcert CA from:
#       ~/.config/mkcert
# 
# - Generates server cert + key for:
#       vaultwarden.local  AND  192.168.2.125
# 
# - Stores them in:
#       ~/.config/ssl/vaultwarden
#       - vaultwarden.local.pem
#       - vaultwarden.local-key.pem
# 
# - Exports mkcert CA root as:
#       ~/.config/ssl/vaultwarden/rootCA.crt
#
# Activation output:
# - Silent when the cert, key, and CA copy are all present and owned
#   correctly.
# - Logs only when it issues or repairs something, and on error.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  # ---- SHARED PATHS ---- #
  # The CA root and the per-service certificate directory are shared
  # with mkcert.nix and vaultwarden-nginx.nix.
  paths = import ../../../../options/paths.nix { };

  # User that must own the generated certificate files
  userName = paths.user.name;
  caroot   = paths.darwin.home.mkcert;

  # Vaultwarden certs directory
  certDir = "${paths.darwin.home.ssl}/vaultwarden";

  # Server cert + key used by nginx
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  # CA cert for phones (copy of mkcert rootCA.pem)
  caCrt   = "${caroot}/rootCA.crt";

  # Export script (runs at activation, also available in PATH)
  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # ---- NOTHING TO DO ---- #
    # Server cert, key, and the CA copy for phones are all in place and
    # the directory belongs to the user, so there is no work to report.
    #
    # ** Ownership is part of the check on purpose: a cert directory
    # ** left owned by root is exactly the state this script exists to
    # ** repair, and skipping on file existence alone would hide it.
    if [ -f "${certPem}" ] \
      && [ -f "${keyPem}" ] \
      && [ -f "${caCrt}" ] \
      && [ "$(${paths.darwin.system.bin.stat} -f '%Su' "${certDir}" 2>/dev/null || true)" = "${userName}" ]; then
      exit 0
    fi

    # ---- WORK IS NEEDED ---- #
    # From here on every step reports, because something changed.
    echo ">>> [vw-cert] CAROOT:   ${caroot}"
    echo ">>> [vw-cert] CERT DIR: ${certDir}"

    # Ensure certDir exists
    mkdir -p "${certDir}"
    chmod 755 "${certDir}"

	# Generate server cert + key if they don't exist
    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vw-cert] Generating mkcert cert+key for:"
      echo ">>>            - vaultwarden.local"
      echo ">>>            - 192.168.2.125"
      
      # Use mkcert to generate the cert and key
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \

        # Add SANs for both hostname and IP
        vaultwarden.local 192.168.2.125 || {
          echo "!!! [vw-cert] mkcert FAILED while issuing server cert"
          exit 1
        }
      echo ">>> [vw-cert] New server cert + key created"
    fi

    # Export mkcert CA → rootCA.crt for phones
    if [ -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [vw-cert] Exporting mkcert root CA → ${caCrt}"
      cp "${caroot}/rootCA.pem" "${caCrt}"
      echo ">>> [vw-cert] You can import rootCA.crt on iOS/Android"
    else
      # If mkcert rootCA.pem is missing, warn the user
      echo "!!! [vw-cert] mkcert rootCA.pem NOT found in ${caroot}"
      echo "!!! [vw-cert] If CA is broken, run once:"
      echo "!!!           CAROOT=\"${caroot}\" mkcert -install"
    fi

    # Fix ownership + permissions
    echo ">>> [vw-cert] Fixing ownership + permissions"
    chown -R "${userName}:staff" "${certDir}" || {
      echo "!!! [vw-cert] chown failed (continuing)"
    }

    # nginx master runs as root; it can read 600.
    chmod 600 "${keyPem}" || echo "!!! [vw-cert] chmod 600 key failed (continuing)"
    chmod 644 "${certPem}" "${caCrt}" || echo "!!! [vw-cert] chmod 644 cert/crt failed (continuing)"

    echo ">>> [vw-cert] DONE: Vaultwarden SSL setup"
  '';
in
{
  # Expose helper in PATH (optional, nice for debugging)
  environment.systemPackages = [ vwCertScript ];

  # Run it automatically on every activation (same pattern as cleanup + rsync)
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    # ** The script is silent when there is nothing to do, so no banner
    # ** is printed here either.
    ${vwCertScript}/bin/vaultwarden-cert-setup || echo "!!! vaultwarden-cert-setup failed (continuing)"
  '';
}
