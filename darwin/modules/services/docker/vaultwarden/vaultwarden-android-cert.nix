# /Users/ven/.config/nix/nix-config/darwin/modules/services/docker/vaultwarden/vaultwarden-android-cert.nix
#
# VAULTWARDEN: ANDROID CA EXPORT
# ============================================================
# - DOES NOT touch nginx or server certs
# - Reads existing mkcert CA:
#       ~/.config/mkcert/rootCA.pem
# - Exports Android-friendly copies:
#       ~/.config/mkcert/rootCA-android.crt  (PEM)
#       ~/.config/mkcert/rootCA-android.der  (DER)
# - Safe to run at every activation.
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;

  # mkcert CAROOT
  caroot        = "${userHome}/.config/mkcert";

  # Android export targets
  androidPemCrt = "${caroot}/rootCA-android.crt";
  androidDerCrt = "${caroot}/rootCA-android.der";

  androidExportScript = pkgs.writeShellScriptBin "vaultwarden-android-cert-export" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vw-android] START: Exporting mkcert CA for Android"
    echo ">>> [vw-android]   CAROOT: ${caroot}"

    # We ONLY read rootCA.pem. If it does not exist, we do nothing.
    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo "!!! [vw-android] ${caroot}/rootCA.pem not found; nothing to export"
      exit 0
    fi

    # 1) Plain PEM copy with .crt extension (many Androids accept this)
    echo ">>> [vw-android] Writing PEM copy -> ${androidPemCrt}"
    cp "${caroot}/rootCA.pem" "${androidPemCrt}" || {
      echo "!!! [vw-android] cp rootCA.pem -> rootCA-android.crt failed"
      exit 1
    }
    chmod 644 "${androidPemCrt}" || true

    # 2) DER-encoded variant (some Android setups prefer DER)
    echo ">>> [vw-android] Writing DER copy -> ${androidDerCrt}"
    "${pkgs.openssl}/bin/openssl" x509 \
      -in "${caroot}/rootCA.pem" \
      -out "${androidDerCrt}" \
      -outform der || {
        echo "!!! [vw-android] openssl DER export failed (continuing with PEM only)"
        exit 0
      }
    chmod 644 "${androidDerCrt}" || true

    echo ">>> [vw-android] DONE:"
    echo ">>>   Import ONE of these on Android as a CA certificate:"
    echo ">>>     - ${androidPemCrt}"
    echo ">>>     - ${androidDerCrt}"
  '';
in
{
  # Helper in PATH (so you can run it manually if you ever want)
  environment.systemPackages = [
    androidExportScript
    pkgs.openssl
  ];

  # Run automatically at activation.
  # DOES NOT call mkcert, DOES NOT modify nginx, ONLY exports extra files.
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running vaultwarden-android-cert-export"
    ${androidExportScript}/bin/vaultwarden-android-cert-export || echo "!!! vaultwarden-android-cert-export failed (continuing)"
  '';
}
