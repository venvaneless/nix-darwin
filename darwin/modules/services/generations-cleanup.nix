# /Users/ven/dotfiles/nix/stable/darwin/modules/services/generations-cleanup.nix
#
# SYSTEM: GENERATIONS CLEANUP
# ============================================================
# Runs cleanup-generations during every darwin activation.
# Embedded with writeShellScriptBin so it always works under root.
# ============================================================

{ lib, pkgs, ... }:

let
  cleanupScript = pkgs.writeShellScriptBin "cleanup-generations" ''
    #!/bin/bash
    set -euo pipefail

    keep=5
    days=30d
    profile="/nix/var/nix/profiles/system"

    echo "=== Cleaning old nix-darwin generations ==="

    gens=$(nix-env --list-generations --profile "$profile" 2>/dev/null \
      | awk '{print $1}' | sort -n)

    total=$(echo "$gens" | wc -l | tr -d ' ')
    echo "Total generations: $total"

    if [ "$total" -gt "$keep" ]; then
      remove=$(echo "$gens" | head -n -"$keep")

      echo "Removing:"
      echo "$remove"

      for g in $remove; do
        nix-env --delete-generations "$g" --profile "$profile" || true
      done
    else
      echo "No generations to remove."
    fi

    echo "Running nix-collect-garbage --delete-older-than $days"
    nix-collect-garbage --delete-older-than "$days" || true

    echo "=== Cleanup complete ==="
  '';
in
{
  # IMPORTANT:
  # - No "config." prefix
  # - Hook into a *real* activation slot: extraActivation
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running cleanup-generations (system)"
    ${cleanupScript}/bin/cleanup-generations || echo "cleanup-generations failed (ignored)"
  '';
}
