# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL (EXTERNAL DISPATCHER)
# ============================================================
# Purpose:
#   - Run your external dispatcher script during darwin activation:
#       /Users/ven/.config/nix/nix-scripts/rsync-all.sh
#
# Guarantees:
#   - Does NOT run rsync-*.sh by glob from Nix
#   - Selection happens ONLY inside rsync-all.sh
#   - Hard timeout ensures activation cannot hang forever
#   - Does NOT touch iCloud / FileProvider / permissions
# ============================================================

{ lib, pkgs, ... }:

let
  dispatcherScript = "/Users/ven/.config/nix/nix-scripts/rsync-all.sh";

  runDispatcher = pkgs.writeShellScriptBin "rsync-all-external" ''
    #!/bin/bash
    set -euo pipefail

    LOG_PREFIX="[system][rsync-all][external]"
    TIMEOUT_BIN="${pkgs.coreutils}/bin/timeout"

    echo "$LOG_PREFIX Starting external dispatcher"
    echo "$LOG_PREFIX Dispatcher: ${dispatcherScript}"

    if [ ! -f "${dispatcherScript}" ]; then
      echo "$LOG_PREFIX WARNING: dispatcher not found — skipping"
      exit 0
    fi

    if [ ! -x "${dispatcherScript}" ]; then
      echo "$LOG_PREFIX WARNING: dispatcher not executable — skipping"
      echo "$LOG_PREFIX Fix with: chmod +x ${dispatcherScript}"
      exit 0
    fi

    # ----------------------------------------------------------
    # HARD TIMEOUT (prevents drs from hanging indefinitely)
    # ----------------------------------------------------------
    # If you want a different limit, change 30m.
    # ----------------------------------------------------------
    echo "$LOG_PREFIX Running with timeout: 30m"
    "$TIMEOUT_BIN" 30m "${dispatcherScript}" \
      || echo "$LOG_PREFIX WARNING: dispatcher failed or timed out (ignored)"

    echo "$LOG_PREFIX External dispatcher complete"
  '';
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running rsync-all (external)"
    ${runDispatcher}/bin/rsync-all-external
  '';
}
