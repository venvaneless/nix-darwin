# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all-old.nix
#
# SYSTEM: RSYNC-ALL DISPATCHER (SINGLE ENTRYPOINT)
# ============================================================
# Purpose:
#   - Trigger the external rsync-all.sh dispatcher
#   - Do NOT glob or select scripts here
#   - Selection logic lives ONLY in rsync-all.sh
# ============================================================

{ lib, pkgs, ... }:

let
  dispatcher = "/Users/ven/.config/nix/nix-scripts/rsync-all.sh";
in
{
  system.activationScripts.rsyncAll = lib.mkAfter ''
    echo ">>> [rsync-all] starting dispatcher"

    if [ ! -x "${dispatcher}" ]; then
      echo ">>> [rsync-all] ERROR: dispatcher not executable"
      exit 0
    fi

    "${dispatcher}" || echo ">>> [rsync-all] dispatcher failed (ignored)"
  '';
}
