# darwin/system-commands/rsync.nix
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
  # Path for backup scripts
  scriptDir = "/Users/ven/.config/nix/nix-scripts";

  # ---- TIMEOUTS
  # Total time allowed per script before SIGTERM, then SIGKILL.
  # Adjust if needed for slow backups.
  timeoutSec = "120";
  killAfter  = "5";

  timeoutBin = "${pkgs.coreutils}/bin/timeout";

  # ---- Scripts List
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

  # Execute each script with timeout and logging
  runner = pkgs.writeShellScriptBin "rsync-all" ''
    #!/bin/bash
    set -euo pipefail
    # Paths for logging, timeouts, scripts and execution
    LOG_PREFIX="[system][rsync-all]"
    SCRIPT_DIR="${scriptDir}"
    TIMEOUT_BIN="${timeoutBin}"
    TIMEOUT_SEC="${timeoutSec}"
    KILL_AFTER="${killAfter}"

    # Print initial information about starting the backup runner
    echo "$LOG_PREFIX START direct backup runner"
    echo "$LOG_PREFIX scriptDir = $SCRIPT_DIR"
    echo "$LOG_PREFIX timeout   = ${timeoutSec}s (kill after ${killAfter}s)"

    # Check if the script directory exists; if not, log an error and exit
    if [ ! -d "$SCRIPT_DIR" ]; then
      echo "$LOG_PREFIX ERROR scriptDir does not exist: $SCRIPT_DIR"
      echo "$LOG_PREFIX DONE (nothing ran)"
      exit 0
    fi

    # Iterate over each script in the scripts list
    ${lib.concatMapStringsSep "\n" (s: ''
      echo "$LOG_PREFIX --------------------------------------------"
      echo "$LOG_PREFIX Considering: ${s}"

      # Check if the script exists and is executable; log accordingly
      if [ ! -f "${s}" ]; then
        echo "$LOG_PREFIX SKIP (missing): ${s}"
        
      # Log a message indicating the script is not executable and skip it
      elif [ ! -x "${s}" ]; then
        echo "$LOG_PREFIX SKIP (not executable): ${s}"
      else

      # Log a message indicating the script is being run
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
  # Add the rsync-all runner to system activation scripts so it runs during rebuild/switch
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> rsync-all: starting DIRECT backups (system activation)"
    ${runner}/bin/rsync-all || echo ">>> rsync-all: runner failed (ignored)"
  '';
}
