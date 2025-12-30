# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all.nix
#
# SYSTEM: RSYNC-ALL DISPATCHER
# ============================================================
# Calls the curated rsync-all.sh script maintained outside Nix.
# Nix does NOT decide which backups run.
# ============================================================

{ lib, pkgs, ... }:

let
  rsyncAllScript = "/Users/ven/dotfiles/nix/scripts/rsync-all.sh";
in
{
	echo ">>> DARWIN_REBUILD_REASON=${DARWIN_REBUILD_REASON:-<unset>}"

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running rsync-all (system)"

    if [ -x "${rsyncAllScript}" ]; then
      "${rsyncAllScript}" || echo ">>> rsync-all failed (ignored)"
    else
      echo ">>> rsync-all script not executable or missing — skipping"
    fi
  '';
}
