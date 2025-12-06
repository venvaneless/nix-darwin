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
#       ~/.config/mkcert/rootCA.crt  (DER, for iOS/Android import)
# - Runs mkcert as user "ven" (NOT root) so chain/identity match your old setup
# - Fixes ownership + permissions only in ssl/vaultwarden so you can clean it up
# - Logs every step during activation.
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;

  # mkcert CAROOT (do not touch layout; global mkcert module owns this)
  caroot   = "${userHome}/.config/mkcert";

  # Vaultwarden TLS dir for nginx server cert
  certDir  = "${userHome}/ven-dots/ssl/vaultwarden";

  # SERVER cert + key for nginx:
  certPem  = "${certDir}/vaultwarden.local.pem";
  keyPem   = "${certDir}/vaultwarden.local-key.pem";

  # mkcert CA files
  caPem    = "${caroot}/rootCA.pem";
  caCrt    = "${caroot}/rootCA.crt";

  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-cert] START: Vaultwarden SSL setup"
    echo ">>> [vw-cert]   CAROOT:    ${caroot}"
    echo ">>> [vw-cert]   CERT DIR:  ${certDir}"

    # ---------------------------------------- #
    # 0) Basic checks (mkcert CA must already exist)
    # ---------------------------------------- #
    if [ ! -f "${caPem}" ]; then
      echo "!!! [vw-cert] mkcert rootCA.pem NOT found at ${caPem}"
      echo "!!! [vw-cert] Global mkcert module must install CA first."
      echo "!!! [vw-cert] Aborting Vaultwarden cert setup to avoid breaking browsers."
      exit 1
    fi

    # ---------------------------------------- #
    # 1) Directory prep (server cert/key only)
    # ---------------------------------------- #
    echo ">>> [vw-cert] Preparing Vaultwarden cert directory"
    mkdir -p "${certDir}"
    chmod 755 "${certDir}" || true

    # ---------------------------------------- #
    # 2) Server cert + key (vaultwarden.local + IP), via user 'ven'
    # ---------------------------------------- #
    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vw-cert] No existing cert+key → issuing new mkcert pair as user '${userName}'"
      echo ">>> [vw-cert]   hosts:"
      echo ">>> [vw-cert]     - vaultwarden.local"
      echo ">>> [vw-cert]     - 192.168.2.125"

      /usr/bin/sudo -u "${userName}" \
        CAROOT="${caroot}" \
        "${pkgs.mkcert}/bin/mkcert" \
          -cert-file "${certPem}" \
          -key-file  "${keyPem}" \
          vaultwarden.local 192.168.2.125 || {
            echo "!!! [vw-cert] mkcert FAILED while issuing server cert as ${userName}"
            exit 1
          }

      if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
        echo "!!! [vw-cert] mkcert reported success but cert/key are missing:"
        echo "!!! [vw-cert]   cert: ${certPem}"
        echo "!!! [vw-cert]   key : ${keyPem}"
        exit 1
      fi

      echo ">>> [vw-cert] New server cert + key created ✅"
    else
      echo ">>> [vw-cert] Existing cert + key found, reusing"
      echo ">>> [vw-cert]   cert: ${certPem}"
      echo ">>> [vw-cert]   key : ${keyPem}"
    fi

    # ---------------------------------------- #
    # 3) Export mkcert CA → rootCA.crt (DER, single file for phones)
    #    NOTE: stays in CAROOT (~/.config/mkcert), like you wanted.
    # ---------------------------------------- #
    if [ -f "${caPem}" ]; then
      echo ">>> [vw-cert] Exporting mkcert root CA (PEM → DER)"
      echo ">>> [vw-cert]   source PEM: ${caPem}"
      echo ">>> [vw-cert]   target CRT: ${caCrt}"

      "${pkgs.openssl}/bin/openssl" x509 \
        -in "${caPem}" \
        -out "${caCrt}" \
        -outform der || {
          echo "!!! [vw-cert] openssl DER export FAILED"
          exit 1
        }

      if [ ! -f "${caCrt}" ]; then
        echo "!!! [vw-cert] Expected CA CRT not found at ${caCrt} after export"
        exit 1
      fi

      chmod 644 "${caCrt}" || echo "!!! [vw-cert] chmod 644 on ${caCrt} failed (continuing)"
      echo ">>> [vw-cert] mkcert root CA exported as DER ✅"
      echo ">>> [vw-cert]   Import this on iOS/Android:"
      echo ">>> [vw-cert]   - ${caCrt}"
    else
      echo "!!! [vw-cert] mkcert rootCA.pem disappeared mid-run, this should not happen"
      exit 1
    fi

    # ---------------------------------------- #
    # 4) Fix ownership + permissions (Vaultwarden cert dir ONLY)
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

  # Run automatically on every activation
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-cert-setup"
    ${vwCertScript}/bin/vaultwarden-cert-setup || echo "!!! vaultwarden-cert-setup failed (continuing)"
  '';
}
