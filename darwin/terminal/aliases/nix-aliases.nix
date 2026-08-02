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

    # ---- Open the Nix configuration repository
    ## Changes the current terminal to the flake's root directory
    ncfg = "cd ${flakePath}";

    # ---- Open the Nix scripts directory
    ## Changes the current terminal to the directory containing helper scripts
    nscripts = "cd ${scriptsPath}";

    # ---- Build and activate the Darwin configuration
    ## Creates a new system generation, switches to it, and runs activation
    drs = "sudo -H darwin-rebuild switch --flake ${flakePath}#${flakeHost}";

    # ---- Build the Darwin configuration without activating it
    ## Builds the system and creates a result link, but does not switch generations
    drb = "sudo -H darwin-rebuild build --flake ${flakePath}#${flakeHost}";

    # ---- Build + check-mode activation
    ## Builds the system, then runs its activation script in check mode without switching generations
    rcheck = "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}";

    # ---- Validate the flake configuration
    ## Evaluates standard flake outputs and builds anything declared under checks
    ncheck = "nix flake check ${flakePath}";

    # ---- Validate the flake configuration with build logs
    ## Same as ncheck, but prints detailed output for each check build
    "nl-check" = "nix flake check ${flakePath} --print-build-logs";

    # ---- Evaluate the Darwin configuration without building it
    ## Prints the system derivation path without building, switching, or activating
    neval = "nix eval ${flakePath}#darwinConfigurations.${flakeHost}.config.system.build.toplevel.drvPath";

    # ---- Build the Darwin configuration without activation
    ## Builds the full system without creating a result link, switching, or activating
    rsafe = "sudo -H nix build ${flakePath}#darwinConfigurations.${flakeHost}.system --no-link";

    # ---- Show the flake outputs
    ## Lists the packages, applications, and other outputs exposed by the flake
    nshow = "nix flake show ${flakePath}";

    # ---- Update the flake inputs
    ## Fetches the latest locked inputs and writes the updated flake.lock file
    "flake-update" = "nix flake update --flake ${flakePath}";
  };
  
  programs.fish.functions = {
    # ---------------------------------------------------------
    # ---- nvalidate -> Evaluate, build, and save the output ---- #
    # Evaluates and then builds the Darwin system without switching
    # generations or running activation. Both command outputs are shown
    # in the terminal and saved in the main Downloads folder.
    # ---------------------------------------------------------
    nvalidate = ''
      function nvalidate --description "Evaluate and build the Darwin configuration with a Downloads log"
        set -l flake_path "${flakePath}"
        set -l flake_host "${flakeHost}"
        set -l downloads_dir "/Users/ven/Downloads"
        set -l timestamp (command date "+%Y-%m-%d-%H%M%S")
        set -l log_file "$downloads_dir/$timestamp-nix-eval.log"

        if not test -d "$downloads_dir"
          echo "Downloads folder does not exist: $downloads_dir" >&2
          return 1
        end

        echo "Writing validation output to:"
        echo "$log_file"

        begin
          echo "Nix Darwin validation"
          echo "Started: "(command date "+%Y-%m-%d %H:%M:%S %Z")
          echo "Flake: $flake_path#$flake_host"
          echo
          echo "=== Evaluating the Darwin configuration ==="

          if not nix eval "$flake_path#darwinConfigurations.$flake_host.config.system.build.toplevel.drvPath"
            echo "Evaluation failed. The system build was not started."
            false
          else
            echo
            echo "=== Building the Darwin configuration without activation ==="
            sudo -H nix build "$flake_path#darwinConfigurations.$flake_host.system" --no-link
          end
        end 2>&1 | command tee "$log_file"

        set -l pipeline_status $pipestatus

        if test $pipeline_status[2] -ne 0
          echo "Could not save the validation output to: $log_file" >&2
          return 1
        end

        return $pipeline_status[1]
      end
    '';
    # ---------------------------------------------------------

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
