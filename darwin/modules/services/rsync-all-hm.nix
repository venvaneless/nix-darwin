# /Users/ven/dotfiles/nix/darwin/modules/services/rsync-all-hm.nix
#
# HOME MANAGER: RSYNC-ALL (user-level)
# ============================================================
# Runs rsync-all.sh during Home Manager activation.
# ============================================================

{ config, lib, pkgs, ... }:

let
  scriptPath = "/Users/ven/dotfiles/nix/scripts/rsync-all.sh";
in
{
  home.activation.rsyncAllUser =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -x "${scriptPath}" ]; then
        echo "Running rsync-all.sh (HM)…"
        "${scriptPath}" || true
      fi
    '';
}
