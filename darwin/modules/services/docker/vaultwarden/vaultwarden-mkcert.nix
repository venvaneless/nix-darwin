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
#       ~/ven-dots/ssl/vaultwarden/rootCA.crt
#   for iOS/Android import.
# ============================================================

{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;
  caroot   = "${userHome}/.config/mkcert";

  certDir = "${userHome}/ven-dots/ssl/vaultwarden";

  # SERVER cert + key for nginx:
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";

  # CA cert for mobile devices:
  caCrt   = "${certDir}/rootCA.crt";

  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-cert] Ensuring Vaultwarden SSL certificates"
    echo ">>> [vw-cert]   CAROOT:   ${caroot}"
    echo ">>> [vw-cert]   cert dir: ${certDir}"

    mkdir -p "${certDir}"
    CAROOT="${caroot}"

    # 1. Issue/reuse server certificate for vaultwarden.local + 192.168.2.125
    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
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
    else
      echo ">>> [vw-cert] Existing Vaultwarden cert/key found, reusing"
    fi

    # 2. Export mkcert CA root as .crt for phones
    if [ -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [vw-cert] Exporting mkcert root CA → ${caCrt}"
      cp "${caroot}/rootCA.pem" "${caCrt}"
      echo ">>> [vw-cert] You can now import rootCA.crt on iOS/Android"
    else
      echo "!!! [vw-cert] mkcert rootCA.pem not found in ${caroot}"
      echo "!!! [vw-cert] Run manually (once):"
      echo "!!!           CAROOT=\"${caroot}\" mkcert -install"
    fi
  '';
in
{
  # Expose script in PATH
  environment.systemPackages = [ vwCertScript ];

  # Run it every activation
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-cert-setup"
    ${vwCertScript}/bin/vaultwarden-cert-setup || echo "!!! vaultwarden-cert-setup failed (continuing)"
  '';
}
