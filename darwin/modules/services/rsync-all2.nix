# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/rsync-all2.nix
#
# SYSTEM: RSYNC-ALL (SELECTIVE)
# ============================================================
# Triggers selective backup execution during
# `darwin-rebuild switch`.
#
# - NEVER decides which backups run
# - NEVER globs scripts
# - Delegates all policy to rsync-all.sh
# ============================================================

{ lib, ... }:

{
	system.activationScripts.extraActivation.text = lib.mkAfter ''
  echo ">>> rsync-all: starting selective backups (system activation)"
  /Users/ven/.config/nix/nix-scripts/rsync-all2.sh \
    || echo ">>> rsync-all: failed (ignored)"
'';
}
