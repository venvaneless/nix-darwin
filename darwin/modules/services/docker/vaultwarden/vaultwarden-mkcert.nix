# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-mkcert.nix
#
# VAULTWARDEN: CERTIFICATES (MKCERT)
# ============================================================
# - Generates server cert + key for:
#       vaultwarden.local  AND  192.168.2.125
# - Stores them in:
#       ~/ven-dots/ssl/vaultwarden
#       - vaultwarden.local.pem
#       - vaultwarden.local-key.pem
# - Exports mkcert CA root as:
#       ~/.config/mkcert/rootCA.crt  (DER, single file for iOS/Android)
# - Fixes ownership + permissions so:
#       - nginx (root) can read the key
#       - user "ven" can read the CRT and PEM
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;
  caroot   = "${userHome}/.config/mkcert";

  # Directory for Vaultwarden server cert + key
  certDir = "${userHome}/ven-dots/ssl/vaultwarden";

  # SERVER cert + key for nginx:
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  # Single CA cert for mobile devices (DER), lives in mkcert CAROOT:
  caCrt   = "${caroot}/rootCA.crt";

  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-cert] Ensuring Vaultwarden SSL certificates"
    echo ">>> [vw-cert]   CAROOT:   ${caroot}"
    echo ">>> [vw-cert]   cert dir: ${certDir}"

    # Create directory for Vaultwarden cert/key
    mkdir -p "${certDir}"
    CAROOT="${caroot}"

    # --- 1. Issue/reuse server certificate for vaultwarden.local + 192.168.2.125 ---
    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vw-cert] No existing Vaultwarden cert/key found."
      echo ">>> [vw-cert] Generating new mkcert cert+key for:"
      echo ">>>            - vaultwarden.local"
      echo ">>>            - 192.168.2.125"

      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \
        vaultwarden.local 192.168.2.125 || {
          echo "!!! [vw-cert] mkcert failed while issuing server cert"
          exit 1
        }

      # Sanity check: files should exist after mkcert
      if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
        echo "!!! [vw-cert] mkcert reported success but cert/key are missing."
        echo "!!! [vw-cert] Expected:"
        echo "!!!            - ${certPem}"
        echo "!!!            - ${keyPem}"
        exit 1
      fi

      echo ">>> [vw-cert] New Vaultwarden cert/key generated ✅"
    else
      echo ">>> [vw-cert] Existing Vaultwarden cert/key found, reusing"
      echo ">>> [vw-cert]   cert: ${certPem}"
      echo ">>> [vw-cert]   key : ${keyPem}"
    fi

    # --- 2. Export mkcert CA root as DER .crt (single file for iOS + Android) ---
    if [ -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [vw-cert] Exporting mkcert root CA as DER"
      echo ">>> [vw-cert]   source PEM: ${caroot}/rootCA.pem"
      echo ">>> [vw-cert]   target CRT: ${caCrt}"

      "${pkgs.openssl}/bin/openssl" x509 \
        -in "${caroot}/rootCA.pem" \
        -out "${caCrt}" \
        -outform der || {
          echo "!!! [vw-cert] openssl DER export failed"
          exit 1
        }

      # Sanity check: CA CRT must exist after export
      if [ ! -f "${caCrt}" ]; then
        echo "!!! [vw-cert] Expected CA CRT not found at ${caCrt} after export"
        exit 1
      fi

      echo ">>> [vw-cert] mkcert root CA exported as DER ✅"
      echo ">>> [vw-cert]   Import this on phones:"
      echo ">>> [vw-cert]   - ${caCrt}"
    else
      echo "!!! [vw-cert] mkcert rootCA.pem not found in ${caroot}"
      echo "!!! [vw-cert] Run manually (once, if needed):"
      echo "!!!           CAROOT=\"${caroot}\" mkcert -install"
      echo "!!! [vw-cert] Then rerun drs so vaultwarden-cert-setup can re-export the CA."
    fi

    # --- 3. Fix ownership + permissions so nginx + ven both work ---
    echo ">>> [vw-cert] Fixing ownership + permissions"
    chown -R root:staff "${certDir}" || echo "!!! [vw-cert] chown root:staff failed (continuing)"

    # Private key: strict perms
    chmod 600 "${keyPem}" || echo "!!! [vw-cert] chmod 600 key failed (continuing)"

    # Public cert + CA: readable
    chmod 644 "${certPem}" || echo "!!! [vw-cert] chmod 644 cert failed (continuing)"
    if [ -f "${caCrt}" ]; then
      chmod 644 "${caCrt}" || echo "!!! [vw-cert] chmod 644 CA CRT failed (continuing)"
    fi

    echo ">>> [vw-cert] Vaultwarden SSL setup finished."
  '';
in
{
  # Expose script in PATH
  environment.systemPackages = [ vwCertScript ];

  # Run it every activation (using the known-good hook)
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-cert-setup"
    ${vwCertScript}/bin/vaultwarden-cert-setup || echo "!!! vaultwarden-cert-setup failed (continuing)"
  '';
}
