# /Users/ven/.config/nix/nix-config/darwin/modules/services/generations-cleanup.nix
#
# ============================================================
# SYSTEM: GENERATIONS CLEANUP
#
# Provides cleanup-generations as a manually run system command.
# Cleanup does not run automatically during darwin activation.
# ============================================================

{ pkgs, ... }:

let
  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: SETTINGS ----- #
  # Configure how many generations and how many days to retain
  # -----------------------------------------------------

  generationsToKeep = 5;
  garbageCollectionAge = "30d";
  systemProfile = "/nix/var/nix/profiles/system";


  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: COMMAND ----- #
  # Create the cleanup-generations executable
  # -----------------------------------------------------

  cleanupScript = pkgs.writeShellScriptBin "cleanup-generations" ''
    #!/usr/bin/env bash
    set -euo pipefail

    keep=${toString generationsToKeep}
    days="${garbageCollectionAge}"
    profile="${systemProfile}"

    echo "=== Cleaning old nix-darwin generations ==="

    generations="$(
      ${pkgs.nix}/bin/nix-env \
        --list-generations \
        --profile "$profile" \
        2>/dev/null \
        | ${pkgs.gawk}/bin/awk '{ print $1 }' \
        | ${pkgs.coreutils}/bin/sort -n
    )"

    if [ -n "$generations" ]; then
      total="$(
        printf '%s\n' "$generations" \
          | ${pkgs.coreutils}/bin/wc -l \
          | ${pkgs.coreutils}/bin/tr -d ' '
      )"
    else
      total=0
    fi

    echo "Total generations: $total"
    echo "Generations to keep: $keep"

    if [ "$total" -gt "$keep" ]; then
      removeCount=$((total - keep))

      generationsToRemove="$(
        printf '%s\n' "$generations" \
          | ${pkgs.coreutils}/bin/head -n "$removeCount"
      )"

      echo "Removing generations:"
      printf '%s\n' "$generationsToRemove"

      while IFS= read -r generation; do
        if [ -n "$generation" ]; then
          ${pkgs.nix}/bin/nix-env \
            --delete-generations "$generation" \
            --profile "$profile"
        fi
      done <<EOF
$generationsToRemove
EOF
    else
      echo "No generations to remove."
    fi

    echo "Collecting unreachable Nix store paths older than $days..."

    if ${pkgs.nix}/bin/nix-collect-garbage \
      --delete-older-than "$days"
    then
      echo "Garbage collection completed successfully."
    else
      echo "Garbage collection failed." >&2
      exit 1
    fi

    echo "=== Cleanup complete ==="
  '';
in
{
  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: SYSTEM COMMAND ----- #
  # Install cleanup-generations into the system PATH
  # -----------------------------------------------------

  environment.systemPackages = [
    cleanupScript
  ];
}