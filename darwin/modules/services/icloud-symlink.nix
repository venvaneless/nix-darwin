# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/icloud-symlink.nix

{ config, lib, pkgs, ... }:

let
  icloudTarget = "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs";
  icloudLink   = "/Users/ven/iCloudDocs";
in
{
  home.activation.icloudDocsSymlink =
    lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      set -euo pipefail

      LOG_PREFIX="[home-manager][icloud]"

      echo "$LOG_PREFIX Checking iCloudDocs symlink state"

      if [ -L "${icloudLink}" ]; then
        echo "$LOG_PREFIX Symlink already exists, skipping:"
        echo "$LOG_PREFIX   ${icloudLink}"
        # ⬅️ DO NOT exit here
      elif [ -e "${icloudLink}" ]; then
        echo "$LOG_PREFIX ERROR: Path exists but is not a symlink:"
        echo "$LOG_PREFIX   ${icloudLink}"
        echo "$LOG_PREFIX Refusing to overwrite. Fix manually."
        exit 1
      elif [ ! -d "${icloudTarget}" ]; then
        echo "$LOG_PREFIX ERROR: iCloud Drive target not found:"
        echo "$LOG_PREFIX   ${icloudTarget}"
        echo "$LOG_PREFIX Enable iCloud Drive and let it initialize first."
        exit 1
      else
        echo "$LOG_PREFIX Creating symlink:"
        echo "$LOG_PREFIX   ${icloudLink} -> ${icloudTarget}"
        ln -s "${icloudTarget}" "${icloudLink}"
        echo "$LOG_PREFIX Symlink created successfully"
      fi
    '';
}
