# /Users/ven/dotfiles/nix/darwin/modules/services/generations-cleanup.nix
#
# SYSTEM: GENERATIONS CLEANUP
# ============================================================
# Runs cleanup-generations.sh during every darwin-rebuild switch.
# Embedded with writeShellScriptBin so it always works under root.
# ============================================================

{ config, lib, pkgs, ... }:

let
  cleanupScript = pkgs.writeShellScriptBin "cleanup-generations" ''
    #!/bin/bash
    set -euo pipefail

    keep=5
    days=30d
    profile="/nix/var/nix/profiles/system"

    AWK="$(command -v awk)"
    echo "=== Cleaning old nix-darwin generations ==="

    gens=$(nix-env --list-generations --profile "$profile" 2>/dev/null \
      | "$AWK" '{print $1}' \
      | sort -n)

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
  system.activationScripts.cleanupGenerations.text = ''
    echo ">>> Running cleanup-generations (system)"
    ${cleanupScript}/bin/cleanup-generations
  '';
}
