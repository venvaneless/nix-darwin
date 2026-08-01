# darwin/services/generations-cleanup.nix
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

  # Check the number of generations to keep
  generationsToKeep = 5;
  systemProfile = "/nix/var/nix/profiles/system";


  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: COMMAND ----- #
  # Create the cleanup-generations executable
  # -----------------------------------------------------

  # Script 
  cleanupScript = pkgs.writeShellScriptBin "cleanup-generations" ''
    set -euo pipefail
 # Check if the system profile exists
    keep=${toString generationsToKeep}

    # Check if the system profile exists
    profile="${systemProfile}"

    # Print initial information
    echo "=== Cleaning nix-darwin generations ==="
    echo "System profile: $profile"
    echo "Generations to keep: $keep"


    # ---------------------------------------------------
    # Read system generations
    # ---------------------------------------------------

    # Read the list of system generations
    generationOutput="$(
      ${pkgs.nix}/bin/nix-env \

      	# List all generations of the system profile
        --list-generations \

        # Specify the system profile to query
        --profile "$profile"
    )"

    # Check if the generation output is empty
    generations="$(
      printf '%s\n' "$generationOutput" \

      	# Extract the generation numbers from the output
        | ${pkgs.gawk}/bin/awk '{ print $1 }' \

        # Sort the generation numbers in ascending order
        | ${pkgs.coreutils}/bin/sort -n
    )"

    # Determine the current system generation
    currentGeneration="$(
    
      # Extract the current generation from the output
      printf '%s\n' "$generationOutput" \

      	# Use awk to find the line containing "current" and print the first field (generation number)
        | ${pkgs.gawk}/bin/awk '/current/ { print $1; exit }'
    )"

    # When no generations are found, exit gracefully
    if [ -z "$generations" ]; then
      echo "No system generations were found."

      # Successfully completed, the script will terminate with a zero exit status
      exit 0
    fi

    # Check if the current generation was successfully determined
    if [ -z "$currentGeneration" ]; then

      # If the current generation cannot be determined, print an error message and exit with a non-zero status
      echo "Unable to determine the current system generation." >&2

      # Error occured, and the script will terminate with a non-zero exit status
      exit 1
    fi

    # Count the total number of generations
    total="$(
      # Count the number of lines in the generations list to determine the total number of generations
      printf '%s\n' "$generations" \
      
        # Use wc to count the number of lines, which corresponds to the total number of generations
        | ${pkgs.coreutils}/bin/wc -l \
        
        # Remove any leading or trailing whitespace from the count
        | ${pkgs.coreutils}/bin/tr -d ' '
    )"

    # Print the current generation and total number of generations
    echo "Current generation: $currentGeneration"
    echo "Total generations: $total"

    
    # ---------------------------------------------------------------------

    # ---------------------------------------------------
    # ------ RETAIN GENERATIONS ----- #
    # ---------------------------------------------------
    keepList="$currentGeneration"

    # Initialize a counter for the number of generations kept
    kept=1

    # Loop through the list of generations to determine which ones to keep
    while IFS= read -r generation; do
      [ -n "$generation" ] || continue

      # Skip the current generation, as it is already included in the keepList
      if [ "$generation" = "$currentGeneration" ]; then
        continue
      fi
      
      # If the number of kept generations is less than the specified limit, add the generation to the keepList
      if [ "$kept" -lt "$keep" ]; then
      	# Add the generation to the keepList
        keepList="$keepList
$generation"
		# Increment the counter for the number of generations kept
        kept=$((kept + 1))
      fi
    done <<EOF
$(

  # Read the list of generations in reverse order to prioritize the most recent ones
  printf '%s\n' "$generations" \
  	# Sort the generations in reverse numerical order to process the most recent generations first
    | ${pkgs.coreutils}/bin/sort -rn
)
EOF
	# Print the list of generations that will be kept
    echo "Keeping generations:"

    # Print the keepList in sorted order for clarity
    printf '%s\n' "$keepList" \
      # Sort the keepList in ascending numerical order for display
      | ${pkgs.coreutils}/bin/sort -n

      # ---------------------------------------------------------------------


    # ---------------------------------------------------------------------

    # ---------------------------------------------------
    # ------ DELETE ALL OTHER GENERATIONS ----- #
    # ---------------------------------------------------

    # Initialize a variable to hold the list of generations to remove
    generationsToRemove=""

    # Loop through the list of generations to determine which ones to remove
    while IFS= read -r generation; do

      # Skip empty lines in the generations list
      [ -n "$generation" ] || continue

      # Check if the generation is in the keepList; if so, skip it
      if printf '%s\n' "$keepList" \

        # Use grep to check if the generation is in the keepList, using -q for quiet mode and -x for exact match
        | ${pkgs.gnugrep}/bin/grep -qx -- "$generation"
      then
        continue
      fi
      
      # If the generation is not in the keepList, add it to the generationsToRemove list
      generationsToRemove="$generationsToRemove
$generation"
    done <<EOF
$generations
EOF

	# Remove any empty lines from the generationsToRemove list
    generationsToRemove="$(
      # Print the generationsToRemove list and filter out empty lines using grep
      printf '%s\n' "$generationsToRemove" \
        | ${pkgs.gnugrep}/bin/grep -v '^$' \
        || true
    )"

    # Print the list of generations to be deleted, if any
    if [ -n "$generationsToRemove" ]; then
      echo "Deleting generations:"
      printf '%s\n' "$generationsToRemove"

      # Loop through the generationsToRemove list and delete each generation using nix-env
      while IFS= read -r generation; do
        [ -n "$generation" ] || continue

        # Delete the specified generation from the system profile using nix-env
        ${pkgs.nix}/bin/nix-env \
          # Specify the generation to delete
          --delete-generations "$generation" \
          
          # Specify the system profile from which to delete the generation
          --profile "$profile"
      done <<EOF
$generationsToRemove
EOF

	# Print a message indicating that the generations have been deleted
    else
      echo "No system generations need to be deleted."
    fi
    # ---------------------------------------------------------------------


    # ---------------------------------------------------------------------

    # ---------------------------------------------------
    # Delete unreachable Nix store data
    # ---------------------------------------------------

    # Print a message indicating that unreachable Nix store paths are being collected
    echo "Collecting all unreachable Nix store paths..."

    # Run nix-collect-garbage to delete all unreachable Nix store paths
    ${pkgs.nix}/bin/nix-collect-garbage

    # Print a message indicating that the cleanup process is complete
    echo "=== Generations cleanup complete ==="
  '';

  # ---------------------------------------------------------------------


# ---------------------------------------------------------------------------------
in
{
  # -----------------------------------------------------
  # ------ GENERATIONS CLEANUP: SYSTEM COMMAND ----- #
  # Install cleanup-generations into the system PATH
  # -----------------------------------------------------

  # Add the cleanup-generations script to the system packages so it can be run as a command
  environment.systemPackages = [
    cleanupScript
  ];
}