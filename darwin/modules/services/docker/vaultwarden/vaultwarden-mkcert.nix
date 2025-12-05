# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/mkcert.nix
#
# MKCERT: GLOBAL SETUP (DARWIN)
# ============================================================
# - Installs mkcert as a system package
# - Ensures mkcert CA is installed into:
#       ~/.config/mkcert
# - Fixes ownership so files are owned by user "ven"
# - Provides helper to export DER .crt for phones
# - Prints clear messages on every activation
# ============================================================

{ config, pkgs, lib, ... }:

let
  userName = "ven";
  userHome = config.users.users.${userName}.home;
  caroot   = "${userHome}/.config/mkcert";

  # MKCERT: INSTALL / ENSURE CA
  # ------------------------------------------------------------
  # - Creates CAROOT directory
  # - Runs mkcert -install only if rootCA.pem is missing
  # - Fixes ownership of CAROOT so mkcert works under user "ven"
  # ------------------------------------------------------------
  mkcertScript = pkgs.writeShellScriptBin "mkcert-install" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [mkcert] Ensuring mkcert CA is installed"
    echo ">>> [mkcert]   CAROOT: ${caroot}"

    # Ensure CAROOT exists
    mkdir -p "${caroot}"

    # Use CAROOT for mkcert
    CAROOT="${caroot}"

    # Only run mkcert -install if rootCA.pem is missing
    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found → running mkcert -install"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install || {
        echo "!!! [mkcert] mkcert -install failed"
        exit 1
      }
    else
      echo ">>> [mkcert] CA already present at ${caroot}/rootCA.pem"
    fi

    echo ">>> [mkcert] Fixing ownership of CAROOT -> ${userName}:staff"
    chown -R "${userName}:staff" "${caroot}" || echo "!!! [mkcert] chown failed (continuing)"
  '';

  # MKCERT: EXPORT CA AS DER FOR PHONES
  # ------------------------------------------------------------
  # - Converts rootCA.pem → rootCA-android.crt using openssl x509
  # - Keeps everything inside ~/.config/mkcert
  # - Does NOT run automatically; you call it manually:
  #       mkcert-export-root-der
  # ------------------------------------------------------------
  mkcertExportScript = pkgs.writeShellScriptBin "mkcert-export-root-der" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [mkcert-export] Exporting mkcert root CA as DER for phones"
    echo ">>> [mkcert-export]   CAROOT: ${caroot}"

    # Check that CAROOT exists and has rootCA.pem
    if [ ! -d "${caroot}" ]; then
      echo "!!! [mkcert-export] CAROOT directory does not exist: ${caroot}"
      echo "!!! [mkcert-export] Run mkcert-install (via drs) first."
      exit 1
    fi

    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo "!!! [mkcert-export] ${caroot}/rootCA.pem not found."
      echo "!!! [mkcert-export] Run mkcert-install (via drs) first."
      exit 1
    fi

    local target="${caroot}/rootCA-android.crt"

    echo ">>> [mkcert-export] Converting PEM → DER"
    echo ">>> [mkcert-export]   source: ${caroot}/rootCA.pem"
    echo ">>> [mkcert-export]   target: ${target}"

    "${pkgs.openssl}/bin/openssl" x509 \
      -in "${caroot}/rootCA.pem" \
      -out "${target}" \
      -outform der || {
        echo "!!! [mkcert-export] openssl DER export failed"
        exit 1
      }

    if [ ! -f "${target}" ]; then
      echo "!!! [mkcert-export] Expected DER file not found at ${target}"
      exit 1
    fi

    chmod 644 "${target}" || echo "!!! [mkcert-export] chmod 644 on ${target} failed (continuing)"

    echo ">>> [mkcert-export] mkcert root CA exported as DER ✅"
    echo ">>> [mkcert-export]   Import this on phones:"
    echo ">>> [mkcert-export]   - ${target}"
  '';
in
{
  # MKCERT TOOLS IN PATH
  # ------------------------------------------------------------
  # - mkcert CLI (from pkgs.mkcert)
  # - mkcert-install (global CA setup, run at activation)
  # - mkcert-export-root-der (manual helper for Android/iOS)
  # ------------------------------------------------------------
  environment.systemPackages = [
    pkgs.mkcert
    pkgs.openssl
    mkcertScript
    mkcertExportScript
  ];

  # GLOBAL ACTIVATION HOOK
  # ------------------------------------------------------------
  # - Always run mkcert-install at activation
  # - Ensures rootCA.pem exists and CAROOT ownership is correct
  # ------------------------------------------------------------
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running mkcert-install (global)"
    ${mkcertScript}/bin/mkcert-install || echo "!!! mkcert-install failed (continuing)"
  '';
}
