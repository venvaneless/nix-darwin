# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/icloud-symlink.nix
#
# ICLOUD DRIVE SYMLINK
# ==============================================================
# Ensures a stable symlink to iCloud exists in the home folder
# Behavior:
# - If the symlink already exists: log and skip
# - If the path exists but is NOT a symlink: fail loudly
# - If missing: create the symlink
# ==============================================================

{ config, lib, pkgs, ... }:

let
  icloudTarget = "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs";
  icloudLink   = "/Users/ven/iCloudDocs";
in
{
  home.activation.icloudDocsSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    LOG_PREFIX="[home-manager][icloud]"

    echo "$LOG_PREFIX Checking iCloudDocs symlink state"

    if [ -L "${icloudLink}" ]; then
      echo "$LOG_PREFIX Symlink already exists, skipping:"
      echo "$LOG_PREFIX   ${icloudLink}"
      exit 0
    fi

    if [ -e "${icloudLink}" ]; then
      echo "$LOG_PREFIX ERROR: Path exists but is not a symlink:"
      echo "$LOG_PREFIX   ${icloudLink}"
      echo "$LOG_PREFIX Refusing to overwrite. Fix manually."
      exit 1
    fi

    if [ ! -d "${icloudTarget}" ]; then
      echo "$LOG_PREFIX ERROR: iCloud Drive target not found:"
      echo "$LOG_PREFIX   ${icloudTarget}"
      echo "$LOG_PREFIX Enable iCloud Drive and let it initialize first."
      exit 1
    fi

    echo "$LOG_PREFIX Creating symlink:"
    echo "$LOG_PREFIX   ${icloudLink} -> ${icloudTarget}"

    ln -s "${icloudTarget}" "${icloudLink}"

    echo "$LOG_PREFIX Symlink created successfully"
  '';
}
