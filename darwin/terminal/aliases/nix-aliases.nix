# darwin/terminal/aliases/nix-aliases.nix
#
# =====================================================================
# NIX-DARWIN: ALIASES
# 
# =====================================================================

{ ... }:

let
  flakePath = "/Users/ven/.config/nix/nix-config";
  flakeHost = "macbook";

  scriptsPath = "/Users/ven/.config/nix/nix-scripts";
in
{
  programs.fish.shellAliases = {

    # ---- Enter the nix configuration directory
    ncfg = "cd ${flakePath}";

    # ---- Enter the nix scripts directory
    # Jump to the directory containing your Nix helper scripts
    nscripts = "cd ${scriptsPath}";

    # ---- Switch to the current nix-darwin configuration
    drs = "sudo -H darwin-rebuild switch --flake ${flakePath}#${flakeHost}";

    # ---- Evaluate and build the flake (No switch)
    drb = "sudo -H darwin-rebuild build --flake ${flakePath}#${flakeHost}";

    # ---- Analyse the configuration for bugs and syntax errors
    ## Checks the configuration for any bugs and syntax errors
    rcheck = "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}";

    # ---- Validate the flake configuration
    ncheck = "nix flake check ${flakePath}";

    # ---- Validate the flake configuration with build logs
    ## Same as "ncheck" but with logs
    "nl-check" = "nix flake check ${flakePath} --print-build-logs";

    # ---- Safely validate if the system can evaluate/build
    rsafe = "sudo -H nix build ${flakePath}#darwinConfigurations.${flakeHost}.system --no-link";

    # ---- Show the flake configuration
    # Shows all outputs exposed by the flake
    nshow = "nix flake show ${flakePath}";

    # ---- Recreate / update flake's lock file
    "nix-update" = "nix flake update --flake ${flakePath}";
  };
  
  programs.fish.functions = {
    # ---------------------------------------------------------
    # ---- pinflake -> Archive and protect flake inputs ---- #
    # Fetches all inputs for a flake and creates indirect GC roots
    # so nix-collect-garbage does not remove them.
    #
    # Defaults to the current directory.
    #
    # Examples:
    # pinflake
    # pinflake /Users/ven/.config/nix/nix-config
    # ---------------------------------------------------------
    pinflake = ''

      # Set the flake path to the current directory or the provided argument
      # '-l' flag is used to create a local variable in fish shell
      set -l flake_path "${flakePath}"


      # If the count of arguments is greater than 0, set the flake path to the first argument
      # '-gt 0' flag checks if the number of arguments is greater than 0
      if test (count $argv) -gt 0

      	# Set the flake path to the first argument provided by the user
        # ** NOTE: 'argv' is a special variable in fish shell that holds all the arguments passed to the function
        # ** '$argv[1]' accesses the first argument passed to the function
        set flake_path "$argv[1]"
      end


      # Check if the specified flake path contains a flake.nix file
      if not test -f "$flake_path/flake.nix"
        echo "Not a flake directory: $flake_path"

        # Return 1 to indicate an error occurred
        return 1
      end

      # Create a directory to store the GC roots for the flake inputs
      set -l root_dir "$HOME/.local/state/nix/gcroots/flake-inputs"

      # Use command to bypass the global mkdir alias.
      command mkdir -p "$root_dir"

      # Print the flake path being archived for user feedback
      echo "Archiving flake inputs from:"
      echo "$flake_path"

      # Use nix flake archive to get the JSON representation of the flake inputs
      set -l archive_json (
        nix flake archive --json "$flake_path"
      )

      # ... or if the nix flake archive command fails, print an error message and return 1
      or begin
        echo "Failed to archive flake inputs."
        return 1
      end


      # Set the store paths by parsing the JSON output from nix flake archive
      set -l store_paths (

      	# Print the JSON output and use jq to extract the store paths of the flake inputs
        printf "%s" "$archive_json" |

        # Output raw strings instead of JSON-encoded strings
        jq -r '
          [
          	# Extract the store paths from the JSON output
            .path?,
            .storePath?,
            (
              # Extract the store paths from the inputs of the flake
              .inputs? // {}

              # Iterate over the values of the inputs object
              | ..
              | objects

              # Select the objects that have a "path" or "storePath" key
              | .path?, .storePath?
            )
          ]

          # Flatten the array of store paths into a single array
          | flatten

          # Select only the elements that are strings and start with "/nix/store/"
          | map(
              select(
                type == "string"
                and startswith("/nix/store/")
              )
            )
            
            # Remove duplicate store paths
          | unique
          | .[]
        '
      )


      # Check if the store paths array is empty, and if so, print an error message and return 1
      if test (count $store_paths) -eq 0
        echo "No flake input store paths were returned."
        return 1
      end


      # For store paths in the store_paths array...
      for store_path in $store_paths

      	# ... create a local variable for each store path in the store_paths array and extract the last component of the store path
        set -l store_name (basename "$store_path")

        # ... create a local variable for the root path by combining the root_dir and store_name
        set -l root_path "$root_dir/$store_name"

		# Remove any existing root path to avoid conflicts        
        command rm -f "$root_path"


        # In nix-store, realise the store path, add an indirect root at the root path, and suppress output
        nix-store \
          --realise "$store_path" \
          --add-root "$root_path" \
          --indirect >/dev/null


        # ... or if the nix-store command fails, print an error message and return 1
        or begin
          echo "Failed to pin: $store_path"
          return 1
        end

        # Print the pinned store path for user feedback
        echo "Pinned: $store_path"
      end


      # Print a message indicating that the flake inputs have been protected from garbage collection, along with the directory where the GC roots are stored
      echo
      echo "Flake inputs protected from garbage collection."
      echo "GC roots: $root_dir"
    '';
    # ---------------------------------------------------------
  };
 }