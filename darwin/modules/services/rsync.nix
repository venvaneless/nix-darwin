# /Users/ven/.config/nix/nix-config/darwin/modules/services/rsync-all.nix
#
# SYSTEM: BACKUP SCRIPT RUNNER
# ============================================================
# Executes backup scripts during darwin-rebuild activation.
#
# Features:
# - Runs an explicit list of backup scripts
# - No globbing or automatic script discovery
# - Supports application, container, certificate,
#   terminal, and user-data backups
# - Runs scripts independently with per-script timeouts
# - Continues even if a script fails
# - Logs start, skip, success, failure, and timeout events
# 
# Safety:
# - Missing scripts are skipped
# - Non-executable scripts are skipped
# - Timeouts prevent activation from hanging
# - Activation never fails because a backup script failed
#
# Script Location:
# - /Users/ven/.config/nix/nix-scripts
#
# Trigger:
# - Runs automatically during darwin-rebuild switch
# ============================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # PATHS
  # ------------------------------------------------------------
  scriptDir = "/Users/ven/.config/nix/nix-scripts";

  # ------------------------------------------------------------
  # TIMEOUTS
  # ------------------------------------------------------------
  # Total time allowed per script before SIGTERM, then SIGKILL.
  # Adjust if needed for slow backups.
  timeoutSec = "120";
  killAfter  = "5";

  timeoutBin = "${pkgs.coreutils}/bin/timeout";

  # ------------------------------------------------------------
  # SCRIPT LIST (EXPLICIT)
  # ------------------------------------------------------------
  scripts = [
   # "${scriptDir}/rsync-a_better_finder_rename.sh"
   # "${scriptDir}/rsync-browsers.sh"
   # "${scriptDir}/rsync-dash.sh"
   # "${scriptDir}/rsync-espanso.sh"
   # "${scriptDir}/rsync-iterm.sh"
   # "${scriptDir}/rsync-lumineo.sh"
   # "${scriptDir}/rsync-mkcert.sh"
   # "${scriptDir}/rsync-obsidian.sh"
   # "${scriptDir}/rsync-other-pref.sh"
   # "${scriptDir}/rsync-paste.sh"
   # "${scriptDir}/rsync-pearcleaner.sh"
   # "${scriptDir}/rsync-raycast.sh"
   # "${scriptDir}/rsync-snippetslab.sh"
   # "${scriptDir}/rsync-vaultwarden.sh"
   # "${scriptDir}/rsync-vesktop.sh"
   # "${scriptDir}/rsync-vlc.sh"
   # "${scriptDir}/rsync-wezterm.sh"
   # "${scriptDir}/rsync-yate.sh"
   # "${scriptDir}/rsync-zed.sh"
  ];

  runner = pkgs.writeShellScriptBin "rsync-all" ''
    #!/bin/bash
    set -euo pipefail

    LOG_PREFIX="[system][rsync-all]"
    SCRIPT_DIR="${scriptDir}"
    TIMEOUT_BIN="${timeoutBin}"
    TIMEOUT_SEC="${timeoutSec}"
    KILL_AFTER="${killAfter}"

    echo "$LOG_PREFIX START direct backup runner"
    echo "$LOG_PREFIX scriptDir = $SCRIPT_DIR"
    echo "$LOG_PREFIX timeout   = ${timeoutSec}s (kill after ${killAfter}s)"

    # ----------------------------------------------------------
    # SAFETY: require script dir
    # ----------------------------------------------------------
    if [ ! -d "$SCRIPT_DIR" ]; then
      echo "$LOG_PREFIX ERROR scriptDir does not exist: $SCRIPT_DIR"
      echo "$LOG_PREFIX DONE (nothing ran)"
      exit 0
    fi

    # ----------------------------------------------------------
    # RUN SCRIPTS (EXPLICIT LIST)
    # ----------------------------------------------------------
    ${lib.concatMapStringsSep "\n" (s: ''
      echo "$LOG_PREFIX --------------------------------------------"
      echo "$LOG_PREFIX Considering: ${s}"

      if [ ! -f "${s}" ]; then
        echo "$LOG_PREFIX SKIP (missing): ${s}"
      elif [ ! -x "${s}" ]; then
        echo "$LOG_PREFIX SKIP (not executable): ${s}"
      else
        echo "$LOG_PREFIX RUN: ${s}"
        # Hard timeout: SIGTERM at TIMEOUT_SEC, SIGKILL after KILL_AFTER
        "$TIMEOUT_BIN" -k "$KILL_AFTER" "$TIMEOUT_SEC" "${s}" \
          && echo "$LOG_PREFIX OK: ${s}" \
          || echo "$LOG_PREFIX WARN: failed or timed out (continued): ${s}"
      fi
    '') scripts}

    echo "$LOG_PREFIX DONE direct backup runner"
  '';
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> rsync-all2: starting DIRECT backups (system activation)"
    ${runner}/bin/rsync-all2-direct || echo ">>> rsync-all2: runner failed (ignored)"
  '';
}
