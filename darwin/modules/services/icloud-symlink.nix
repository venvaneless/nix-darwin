# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/icloud-symlink.nix
#
# DARWIN: ICLOUDDOCS HOME SYMLINK
# ============================================================
# Purpose:
#   - Ensure a convenient ~/iCloudDocs entry exists
#   - Pointing to the real iCloud Drive root
#
# Target (managed by macOS / FileProvider):
#   ~/Library/Mobile Documents/com~apple~CloudDocs
#
# Resulting symlink (user-facing):
#   ~/iCloudDocs -> ~/Library/Mobile Documents/com~apple~CloudDocs
#
# Safety guarantees:
#   - NEVER delete or modify iCloud data
#   - NEVER touch FileProvider internals
#   - NEVER fail Home Manager activation
#   - Idempotent across rebuilds
#   - No repeated symlink recreation
# ============================================================

{ config, lib, ... }:

let
  home         = config.home.homeDirectory;
  icloudTarget = "${home}/Library/Mobile Documents/com~apple~CloudDocs";
  icloudLink   = "${home}/iCloudDocs";
in
{
	# ------------------------------------------------------------
  # EVALUATION MARKER
  # ------------------------------------------------------------
  # This file proves that the module itself is evaluated.
  # It has NO interaction with iCloud and is safe to remove
  # once verification is complete.
  # ------------------------------------------------------------
  home.file."hm-test-icloud-symlink-evaluated.txt".text = ''
    icloud-symlink.nix was evaluated
  '';

  # ------------------------------------------------------------
  # ACTIVATION SCRIPT
  # ------------------------------------------------------------
  # Logic:
  # 1. If ~/iCloudDocs already exists (dir or symlink) → do nothing
  # 2. If iCloud Drive root is not available → do nothing
  # 3. Otherwise create the symlink once
  #
  # Notes:
  # - All exit paths return success (exit 0)
  # - This script MUST NEVER block Home Manager activation
  # ------------------------------------------------------------
  home.activation.icloudDocsSymlink =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      LOG_PREFIX="[home-manager][icloud]"
      echo "$LOG_PREFIX Ensuring iCloudDocs symlink (non-fatal)"

      # ----------------------------------------------------------
      # 1. If ~/iCloudDocs already exists (directory OR symlink)
      #			→ leave untouched
      # ----------------------------------------------------------
      if [ -e "${icloudLink}" ]; then
        echo "$LOG_PREFIX ${icloudLink} already exists — nothing to do"
        exit 0
      fi

      # ------------------------------------------------------------
      # 2. If iCloud Drive root does not exist
      #		→ skip silently (do NOT fail activation)
      # ------------------------------------------------------------
      if [ ! -d "${icloudTarget}" ]; then
        echo "$LOG_PREFIX iCloud Drive not available yet — skipping"
        exit 0
      fi

      # ------------------------------------------------------------
      # 3. Create symlink
      #		→ one-time only
      # ------------------------------------------------------------
      echo "$LOG_PREFIX Creating symlink:"
      echo "$LOG_PREFIX   ${icloudLink} -> ${icloudTarget}"
      ln -s "${icloudTarget}" "${icloudLink}"
      echo "$LOG_PREFIX Symlink created successfully"
    '';
}
