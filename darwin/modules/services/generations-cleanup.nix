# /Users/ven/.config/nix/nix-config/darwin/modules/services/generations-cleanup.nix
#
# ============================================================
# SYSTEM: GENERATIONS CLEANUP
#
# Provides cleanup-generations as a manually run system command.
#
# Behavior:
# - Keeps five nix-darwin system generations
# - Always preserves the currently active generation
# - Deletes all remaining system generations
# - Deletes all unreachable Nix store paths immediately
# - Does not run automatically during darwin activation
# ============================================================

{ pkgs, ... }:

let
  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: SETTINGS ----- #
  # Configure the retained system-generation count
  # -----------------------------------------------------

  generationsToKeep = 5;
  systemProfile = "/nix/var/nix/profiles/system";


  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: COMMAND ----- #
  # Create the cleanup-generations executable
  # -----------------------------------------------------

  cleanupScript = pkgs.writeShellScriptBin "cleanup-generations" ''
    set -euo pipefail

    keep=${toString generationsToKeep}
    profile="${systemProfile}"

    echo "=== Cleaning nix-darwin generations ==="
    echo "System profile: $profile"
    echo "Generations to keep: $keep"


    # ---------------------------------------------------
    # Read system generations
    # ---------------------------------------------------

    generationOutput="$(
      ${pkgs.nix}/bin/nix-env \
        --list-generations \
        --profile "$profile"
    )"

    generations="$(
      printf '%s\n' "$generationOutput" \
        | ${pkgs.gawk}/bin/awk '{ print $1 }' \
        | ${pkgs.coreutils}/bin/sort -n
    )"

    currentGeneration="$(
      printf '%s\n' "$generationOutput" \
        | ${pkgs.gawk}/bin/awk '/current/ { print $1; exit }'
    )"

    if [ -z "$generations" ]; then
      echo "No system generations were found."
      exit 0
    fi

    if [ -z "$currentGeneration" ]; then
      echo "Unable to determine the current system generation." >&2
      exit 1
    fi

    total="$(
      printf '%s\n' "$generations" \
        | ${pkgs.coreutils}/bin/wc -l \
        | ${pkgs.coreutils}/bin/tr -d ' '
    )"

    echo "Current generation: $currentGeneration"
    echo "Total generations: $total"


    # ---------------------------------------------------
    # Select generations to retain
    # ---------------------------------------------------

    keepList="$currentGeneration"
    kept=1

    while IFS= read -r generation; do
      [ -n "$generation" ] || continue

      if [ "$generation" = "$currentGeneration" ]; then
        continue
      fi

      if [ "$kept" -lt "$keep" ]; then
        keepList="$keepList
$generation"
        kept=$((kept + 1))
      fi
    done <<EOF
$(
  printf '%s\n' "$generations" \
    | ${pkgs.coreutils}/bin/sort -rn
)
EOF

    echo "Keeping generations:"
    printf '%s\n' "$keepList" \
      | ${pkgs.coreutils}/bin/sort -n


    # ---------------------------------------------------
    # Delete all other generations
    # ---------------------------------------------------

    generationsToRemove=""

    while IFS= read -r generation; do
      [ -n "$generation" ] || continue

      if printf '%s\n' "$keepList" \
        | ${pkgs.gnugrep}/bin/grep -qx -- "$generation"
      then
        continue
      fi

      generationsToRemove="$generationsToRemove
$generation"
    done <<EOF
$generations
EOF

    generationsToRemove="$(
      printf '%s\n' "$generationsToRemove" \
        | ${pkgs.gnugrep}/bin/grep -v '^$' \
        || true
    )"

    if [ -n "$generationsToRemove" ]; then
      echo "Deleting generations:"
      printf '%s\n' "$generationsToRemove"

      while IFS= read -r generation; do
        [ -n "$generation" ] || continue

        ${pkgs.nix}/bin/nix-env \
          --delete-generations "$generation" \
          --profile "$profile"
      done <<EOF
$generationsToRemove
EOF
    else
      echo "No system generations need to be deleted."
    fi


    # ---------------------------------------------------
    # Delete unreachable Nix store data
    # ---------------------------------------------------

    echo "Collecting all unreachable Nix store paths..."

    ${pkgs.nix}/bin/nix-collect-garbage

    echo "=== Generations cleanup complete ==="
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