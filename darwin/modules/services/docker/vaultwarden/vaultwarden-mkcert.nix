{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;
  caroot   = "${userHome}/.config/mkcert";

  certDir = "${userHome}/ven-dots/ssl/vaultwarden";
  certPem = "${certDir}/vaultwarden.local.pem";
  keyPem  = "${certDir}/vaultwarden.local-key.pem";
  crtFile = "${certDir}/vaultwarden.local-and-ip.crt";

  vwCertScript = pkgs.writeShellScriptBin "vaultwarden-cert-setup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-cert] Creating Vaultwarden certs"

    mkdir -p "${certDir}"

    CAROOT="${caroot}"

    if [ ! -f "${certPem}" ] || [ ! -f "${keyPem}" ]; then
      echo ">>> Generating cert + key"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" \
        -cert-file "${certPem}" \
        -key-file  "${keyPem}" \
        vaultwarden.local 192.168.2.125
    fi

    echo ">>> Exporting CRT for mobile devices"
    cp "${certPem}" "${crtFile}"
  '';
in
{
  environment.systemPackages = [ vwCertScript ];

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-cert-setup"
    ${vwCertScript}/bin/vaultwarden-cert-setup
  '';
}
