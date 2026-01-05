# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/quarantine-fixes.nix
#
# DARWIN: GATEKEEPER / QUARANTINE FIXES
# ============================================================
# Purpose:
#   Declaratively removes the macOS Gatekeeper quarantine flag
#   (com.apple.quarantine) from selected, trusted applications
#   that are managed via Homebrew casks.
#
# Why this exists:
#   - Homebrew casks are downloaded from the internet
#   - macOS assigns a quarantine attribute
#   - nix-homebrew may reapply this on rebuild / reboot
#   - Gatekeeper then repeatedly prompts on app launch
#
# Scope:
#   - System-level (nix-darwin)
#   - Applies ONLY to explicitly listed applications
#
# Safety:
#   - No global Gatekeeper changes
#   - No SIP changes
#   - Idempotent (safe to run on every activation)
# ============================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # CONFIGURATION
  # ------------------------------------------------------------
  # List of trusted applications that should have their
  # quarantine attribute removed after Homebrew installation.
  #
  # To add more apps later:
  #   - Add another entry to this list
  #   - Use absolute paths under /Applications
  #
  trustedApps = [
    {
      name = "Chromium";
      path = "/Applications/Chromium.app";
    }
  ];

  # ------------------------------------------------------------
  # SCRIPT: UNQUARANTINE APPLICATIONS
  # ------------------------------------------------------------
  # Iterates over the trustedApps list and:
  #   - checks whether the app exists
  #   - checks whether the quarantine attribute is present
  #   - removes it if necessary
  #
  unquarantineScript = pkgs.writeShellScript "unquarantine-apps" ''
    set -euo pipefail

    echo "[quarantine-fix] Starting Gatekeeper quarantine check"

    ${lib.concatMapStringsSep "\n" (app: ''
      echo "[quarantine-fix] --------------------------------------------------"
      echo "[quarantine-fix] Checking application: ${app.name}"
      echo "[quarantine-fix] Path: ${app.path}"

      if [ -d "${app.path}" ]; then
        if xattr "${app.path}" | grep -q com.apple.quarantine; then
          echo "[quarantine-fix] Quarantine flag found — removing"
          xattr -dr com.apple.quarantine "${app.path}"
          echo "[quarantine-fix] Quarantine removed successfully"
          
          echo "[quarantine-fix] Re-registering application with Launch Services"
          "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" \
            -f "${app.path}" >/dev/null 2>&1
          
          echo "[quarantine-fix] Launch Services registration refreshed"
        else
          echo "[quarantine-fix] No quarantine flag present — nothing to do"
        fi
      else
        echo "[quarantine-fix] Application not found — skipping"
      fi
    '') trustedApps}

    echo "[quarantine-fix] Completed Gatekeeper quarantine checks"
  '';
in
{
  # ------------------------------------------------------------
  # ACTIVATION
  # ------------------------------------------------------------
  # Runs on every darwin-rebuild switch / boot activation.
  #
  # This ensures that even if Homebrew or macOS reintroduces
  # quarantine flags, they are consistently removed.
  #
  system.activationScripts.removeQuarantineFlags.text = ''
    echo "[activation] Running Gatekeeper quarantine cleanup"
    ${unquarantineScript}
  '';
}
