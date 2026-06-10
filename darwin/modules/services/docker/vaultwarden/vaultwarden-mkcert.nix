# /Users/ven/.config/nix/nix-config/darwin/modules/services/docker/vaultwarden/vaultwarden-mkcert.nix
#
# VAULTWARDEN: CERTIFICATES (MKCERT)
# ============================================================
# - Uses mkcert CA from:
#       ~/.config/mkcert
# - Generates server cert + key for:
#       vaultwarden.local  AND  192.168.2.125
# - Stores them in:
#       ~/.config/ssl/vaultwarden
#       - vaultwarden.local.pem
#       - vaultwarden.local-key.pem
# - Exports mkcert CA root as:
#       ~/.config/ssl/vaultwarden/rootCA.crt
#   for iOS/Android import.
# - Fixes ownership + permissions.
# - Logs all actions during activation.
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;
  caroot   = "${userHome}/.config/mkcert";

  certDir = "${userHome}/.config/ssl/vaultwarden";

  # Server cert + key used by nginx
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  # CA cert for phones (copy of mkcert rootCA.pem)
  caCrt   = "${caroot}/rootCA.crt";

  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-cert] START: Vaultwarden SSL setup"
    echo ">>> [vw-cert]   CAROOT:    ${caroot}"
    echo ">>> [vw-cert]   CERT DIR:  ${certDir}"

    # ---------------------------------------- #
    # Directory prep
    # ---------------------------------------- #
    mkdir -p "${certDir}"
    chmod 755 "${certDir}"

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
    # 2) Export mkcert CA → rootCA.crt for phones
    # ---------------------------------------- #
    if [ -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [vw-cert] Exporting mkcert root CA → ${caCrt}"
      cp "${caroot}/rootCA.pem" "${caCrt}"
      echo ">>> [vw-cert] You can import rootCA.crt on iOS/Android"
    else
      echo "!!! [vw-cert] mkcert rootCA.pem NOT found in ${caroot}"
      echo "!!! [vw-cert] If CA is broken, run once:"
      echo "!!!           CAROOT=\"${caroot}\" mkcert -install"
    fi

    # ---------------------------------------- #
    # 3) Fix ownership + permissions
    # ---------------------------------------- #
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
    echo ">>> Running vaultwarden-cert-setup"
    ${vwCertScript}/bin/vaultwarden-cert-setup || echo "!!! vaultwarden-cert-setup failed (continuing)"
  '';
}
