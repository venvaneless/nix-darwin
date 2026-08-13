# darwin/services/docker/vaultwarden/vaultwarden-android-cert.nix
#
# =====================================================================
# VAULTWARDEN: ANDROID CA EXPORT
# 
# - DOES NOT touch nginx or server certs
# - Reads existing mkcert CA:
#       ~/.config/mkcert/rootCA.pem
# - Exports Android-friendly copies:
#       ~/.config/mkcert/rootCA-android.crt  (PEM)
#       ~/.config/mkcert/rootCA-android.der  (DER)
# - Safe to run at every activation.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  # ---- SHARED PATHS ---- #
  # Reads the CA root created by mkcert.nix; never writes rootCA.pem.
  paths = import ../../../../options/paths.nix { };

  # User that must own the exported certificate copies
  userName = paths.user.name;

  # mkcert CAROOT
  caroot        = paths.darwin.home.mkcert;

  # Android export targets
  androidPemCrt = "${caroot}/rootCA-android.crt";
  androidDerCrt = "${caroot}/rootCA-android.der";

  # Export script (runs at activation, also available in PATH)
  androidExportScript = pkgs.writeShellScriptBin "vaultwarden-android-cert-export" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # We ONLY read rootCA.pem. If it does not exist, we do nothing.
    #
    # ** This one still reports, because a missing CA is an anomaly
    # ** rather than the normal steady state.
    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo "!!! [vw-android] ${caroot}/rootCA.pem not found; nothing to export"
      exit 0
    fi

    # ---- NOTHING TO DO ---- #
    # Both exports exist and neither is older than the CA they were
    # taken from, so they are current and there is nothing to report.
    #
    # ** The age comparison matters: after `mkcert -install` replaces
    # ** the CA, the old exports would still exist and a plain presence
    # ** check would leave phones trusting a CA that is gone.
    if [ -f "${androidPemCrt}" ] \
      && [ -f "${androidDerCrt}" ] \
      && [ ! "${caroot}/rootCA.pem" -nt "${androidPemCrt}" ] \
      && [ ! "${caroot}/rootCA.pem" -nt "${androidDerCrt}" ]; then
      exit 0
    fi

    # ---- WORK IS NEEDED ---- #
    # From here on every step reports, because something changed.
    echo ">>> [vw-android] CAROOT: ${caroot}"

    # 1) Plain PEM copy with .crt extension (many Androids accept this)
    echo ">>> [vw-android] Writing PEM copy -> ${androidPemCrt}"
    cp "${caroot}/rootCA.pem" "${androidPemCrt}" || {
      echo "!!! [vw-android] cp rootCA.pem -> rootCA-android.crt failed"
      exit 1
    }
    chmod 644 "${androidPemCrt}" || true

    # 2) DER-encoded variant (some Android setups prefer DER)
    echo ">>> [vw-android] Writing DER copy -> ${androidDerCrt}"
    
    # Use openssl to convert PEM to DER. If it fails, we continue with PEM only.
    "${pkgs.openssl}/bin/openssl" x509 \
      -in "${caroot}/rootCA.pem" \
      -out "${androidDerCrt}" \
      -outform der || {
        echo "!!! [vw-android] openssl DER export failed (continuing with PEM only)"
        exit 0
      }
    # Set permissions to be readable by user (and others) so Android can read it
    chmod 644 "${androidDerCrt}" || true

    # Print a message to indicate what files were created and how to use them
    echo ">>> [vw-android] DONE:"
    echo ">>>   Import ONE of these on Android as a CA certificate:"
    echo ">>>     - ${androidPemCrt}"
    echo ">>>     - ${androidDerCrt}"
  '';
in
{
  # Helper in PATH (so you can run it manually if you ever want)
  environment.systemPackages = [
  	# Small script that exports the mkcert CA for Android use
    androidExportScript

    # opensssl is a dependency of the export script, it's needed to convert PEM to DER format
    pkgs.openssl
  ];

  # Run automatically at activation.
  # DOES NOT call mkcert, DOES NOT modify nginx, ONLY exports extra files.
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    # ** The script is silent when the exports are already current, so
    # ** no banner is printed here either.
    ${androidExportScript}/bin/vaultwarden-android-cert-export || echo "!!! vaultwarden-android-cert-export failed (continuing)"
  '';
}
