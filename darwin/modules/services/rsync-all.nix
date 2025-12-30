# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL (DISPATCHER MODE)
# ============================================================
# Runs rsync-all.sh during darwin-rebuild switch.
# All selection logic lives in the shell script.
# ============================================================

{ lib, pkgs, ... }:

{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> rsync-all: starting dispatcher backups (system activation)"
    /Users/ven/.config/nix/nix-scripts/rsync-all.sh \
      || echo ">>> rsync-all: failed (ignored)"
  '';
}
