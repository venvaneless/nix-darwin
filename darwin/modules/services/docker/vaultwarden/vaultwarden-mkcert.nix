# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-mkcert.nix
#
# VAULTWARDEN: CERTIFICATES (MKCERT)
# ==================================
# - Provides vaultwarden-cert-setup CLI script.
# - Generates cert + key for vaultwarden.local and 192.168.2.125
# - Places them into:
#       /Users/ven/ven-dots/ssl/vaultwarden
# - Exports a .crt bundle for mobile devices
# ==================================

{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;
  caroot   = "${userHome}/.config/mkcert";

  certDir = "/Users/ven/ven-dots/ssl/vaultwarden";
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";
  crtFile = "${certDir}/vaultwarden.local-and-ip.crt";

  vaultwardenMkcertSetup = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden-mkcert] Preparing certificates in ${certDir}"
    mkdir -p "${certDir}"

    CAROOT="${caroot}"

    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> [vaultwarden-mkcert] Generating new mkcert cert/key"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \
        vaultwarden.local 192.168.2.125 || {
          echo "!!! [vaultwarden-mkcert] mkcert failed"
          exit 1
        }
    else
      echo ">>> [vaultwarden-mkcert] Existing cert and key found, skipping"
    fi

    # Export a .crt bundle for mobile devices
    if [ -f "${certPem}" ]; then
      echo ">>> [vaultwarden-mkcert] Exporting .crt bundle: ${crtFile}"
      cp "${certPem}" "${crtFile}"
    fi
  '';
in
{
  # Expose the script in PATH
  environment.systemPackages = [ vaultwardenMkcertSetup ];

  # Run it automatically on activation
  system.activationScripts.vaultwarden-mkcert.text = lib.mkAfter ''
    "${vaultwardenMkcertSetup}/bin/vaultwarden-cert-setup"
  '';
}
