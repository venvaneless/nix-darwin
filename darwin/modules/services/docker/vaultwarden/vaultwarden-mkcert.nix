# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-mkcert.nix
#
# VAULTWARDEN: CERTIFICATES (MKCERT)
# ============================================================
# - Uses mkcert CA from:
#       ~/.config/mkcert
# - Generates server cert + key for:
#       vaultwarden.local  AND  192.168.2.125
# - Stores server cert + key in:
#       ~/ven-dots/ssl/vaultwarden
#       - vaultwarden.local.pem
#       - vaultwarden.local-key.pem
# - Exports mkcert CA root as:
#       ~/.config/mkcert/rootCA.crt
#   for iOS/Android import (same CA as macOS uses).
# - Fixes ownership + permissions so:
#       - nginx (root) can read the key
#       - user "ven" owns the files and can delete them without sudo
# - Logs every step during activation.
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;

  # mkcert CAROOT
  caroot   = "${userHome}/.config/mkcert";

  # Vaultwarden TLS dir for nginx server cert
  certDir  = "${userHome}/ven-dots/ssl/vaultwarden";

  # SERVER cert + key for nginx:
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  # CA cert for phones (copy of mkcert rootCA.pem, SAME FOLDER as mkcert)
  caCrt   = "${caroot}/rootCA.crt";

  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-cert] START: Vaultwarden SSL setup"
    echo ">>> [vw-cert]   CAROOT:    ${caroot}"
    echo ">>> [vw-cert]   CERT DIR:  ${certDir}"

    # ---------------------------------------- #
    # Directory prep (server cert/key only)
    # ---------------------------------------- #
    mkdir -p "${certDir}"
    chmod 755 "${certDir}" || true

    CAROOT="${caroot}"

    # ---------------------------------------- #
    # 1) Server cert + key (vaultwarden.local + IP)
    # ---------------------------------------- #
    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vw-cert] Generating mkcert cert+key for:"
      echo ">>>            - vaultwarden.local"
      echo ">>>            - 192.168.2.125"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \
        vaultwarden.local 192.168.2.125 || {
          echo "!!! [vw-cert] mkcert FAILED while issuing server cert"
          exit 1
        }
      echo ">>> [vw-cert] New server cert + key created"
    else
      echo ">>> [vw-cert] Existing cert + key found, reusing"
    fi

    # ---------------------------------------- #
    # 2) Export mkcert CA → rootCA.crt (for phones)
    #    NOTE: stays in CAROOT (~/.config/mkcert), like you wanted.
    # ---------------------------------------- #
    if [ -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [vw-cert] Exporting mkcert root CA → ${caCrt}"
      cp "${caroot}/rootCA.pem" "${caCrt}"
      chmod 644 "${caCrt}" || true
      echo ">>> [vw-cert] You can now import rootCA.crt on iOS/Android"
    else
      echo "!!! [vw-cert] mkcert rootCA.pem NOT found in ${caroot}"
      echo "!!! [vw-cert] If CA is broken, run once (already automated by mkcert.nix):"
      echo "!!!           CAROOT=\"${caroot}\" mkcert -install"
    fi

    # ---------------------------------------- #
    # 3) Fix ownership + permissions (Vaultwarden cert dir)
    # ---------------------------------------- #
    echo ">>> [vw-cert] Fixing ownership + permissions for ${certDir}"
    chown -R "${userName}:staff" "${certDir}" || {
      echo "!!! [vw-cert] chown ${userName}:staff ${certDir} failed (continuing)"
    }

    # nginx master runs as root; it can read 600 key.
    chmod 600 "${keyPem}" || echo "!!! [vw-cert] chmod 600 key failed (continuing)"
    chmod 644 "${certPem}" || echo "!!! [vw-cert] chmod 644 cert failed (continuing)"

    echo ">>> [vw-cert] DONE: Vaultwarden SSL setup"
  '';
in
{
  # Helper script in PATH (for debugging if you ever want it)
  environment.systemPackages = [ vwCertScript ];

  # Run automatically on every activation (no manual commands)
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-cert-setup"
    ${vwCertScript}/bin/vaultwarden-cert-setup || echo "!!! vaultwarden-cert-setup failed (continuing)"
  '';
}
