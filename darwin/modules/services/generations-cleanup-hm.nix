# /Users/ven/dotfiles/nix/darwin/modules/services/generations-cleanup-hm.nix
#
# HOME MANAGER: GENERATIONS CLEANUP
# ============================================================
# Embedded version of cleanup-generations, identical logic
# but hooked into HM activation.
# ============================================================

{ config, lib, pkgs, ... }:

let
  scriptPath = "/Users/ven/dotfiles/nix/scripts/cleanup-generations.sh";
in
{
  home.activation.cleanupGenerationsUser =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -x "${scriptPath}" ]; then
        echo "Running cleanup-generations.sh (HM)…"
        "${scriptPath}" || true
      fi
    '';
}
