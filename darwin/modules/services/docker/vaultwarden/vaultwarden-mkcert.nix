# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-mkcert.nix
#
# VAULTWARDEN: CERTIFICATES (MKCERT)
# ==================================
# - Uses mkcert (from mkcert.nix) to generate:
#     - cert + key for vaultwarden.local and 192.168.2.125
# - Stores them under:
#     /Users/ven/ven-dots/ssl/vaultwarden
# - Also exports a .crt bundle for mobile devices.
# ==================================

{ config, pkgs, lib, ... }:

let
  certDir = "/Users/ven/ven-dots/ssl/vaultwarden";
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";
  crtFile = "${certDir}/vaultwarden.local-and-ip.crt";
in
{
  system.activationScripts.vaultwarden-mkcert.text = lib.mkAfter ''
    echo ">>> [vaultwarden-mkcert] Preparing certificates in ${certDir}"
    mkdir -p "${certDir}"

    CAROOT="${HOME}/.config/mkcert"

    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vaultwarden-mkcert] Generating new mkcert cert/key"
      CAROOT="$CAROOT" "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \
        vaultwarden.local 192.168.2.125 || {
          echo "!!! [vaultwarden-mkcert] mkcert failed"
        }
    else
      echo ">>> [vaultwarden-mkcert] Existing cert and key found, skipping generation"
    fi

    # Export a .crt bundle for mobile devices
    if [ -f "${certPem}" ]; then
      echo ">>> [vaultwarden-mkcert] Exporting .crt bundle for mobile: ${crtFile}"
      cp "${certPem}" "${crtFile}"
    fi
  '';
}
