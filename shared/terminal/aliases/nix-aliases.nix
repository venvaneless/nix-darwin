# darwin/terminal/aliases/nix-aliases.nix
#
# =====================================================================
# NIX: ALIASES
#
# Shared Nix aliases and Fish functions for macOS and Linux.
# The same alias names are used on every machine, with the underlying
# rebuild commands selected automatically for nix-darwin or NixOS.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.fish.nixProfile;

  # NIX PATHS
  # =========================
  # Each host can override these paths when its Nix checkout differs.

  flakePath = cfg.flakePath;
  flakeHost = cfg.flakeHost;
  scriptsPath = cfg.scriptsPath;

  # PLATFORM
  # =========================
  # Selects the appropriate system commands and flake output automatically.

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  rebuildCommand =
    if isDarwin then
      "darwin-rebuild"
    else
      "nixos-rebuild";

  systemConfigurations =
    if isDarwin then
      "darwinConfigurations"
    else
      "nixosConfigurations";

  systemBuildTarget =
    if isDarwin then
      "${systemConfigurations}.${flakeHost}.system"
    else
      "${systemConfigurations}.${flakeHost}.config.system.build.toplevel";
in
{
  options.ven.features.terminal.fish.nixProfile = {
    enable = lib.mkEnableOption "shared Nix aliases and functions";

    flakeHost = lib.mkOption {
      type = lib.types.str;
      description = "Flake configuration name for this machine, such as macbook.";
    };

    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/nix/nix-config";
      description = "Path to this machine's Nix flake checkout.";
    };

    scriptsPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/nix/nix-scripts";
      description = "Path to this machine's Nix helper scripts.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish.shellAliases = {

    # ---- Open the Nix configuration repository
    ## Changes the current terminal to the flake's root directory
    ncfg = "cd ${flakePath}";

    # ---- Open the Nix scripts directory
    ## Changes the current terminal to the directory containing helper scripts
    nscripts = "cd ${scriptsPath}";


    # ---------------------------------------------------------
    # ---- REBUILD COMMANDS ---- #
    # Uses darwin-rebuild on macOS and nixos-rebuild on Linux.
    # The host-specific flake name is configured explicitly, because
    # it is not necessarily the operating system hostname.
    # ---------------------------------------------------------

    # ---- Build and activate the system configuration
    ## Creates a new system generation, switches to it, and runs activation
    drs = "sudo -H ${rebuildCommand} switch --flake ${flakePath}#${flakeHost}";

    # ---- Build the system configuration without activating it
    ## Builds the system without switching generations
    drb = "sudo -H ${rebuildCommand} build --flake ${flakePath}#${flakeHost}";

    # ---- Build + check-mode activation
    ## Tests the configuration without permanently switching generations
    rcheck =
      if isDarwin then
        "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}"
      else
        "sudo -H nixos-rebuild test --flake ${flakePath}#${flakeHost}";


    # ---------------------------------------------------------
    # ---- VALIDATION COMMANDS ---- #
    # ---------------------------------------------------------

    # ---- Validate the flake configuration
    ## Evaluates standard flake outputs and builds anything declared under checks
    ncheck = "nix flake check ${flakePath}";

    # ---- Validate the flake configuration with build logs
    ## Same as ncheck, but prints detailed output for each check build
    "nl-check" = "nix flake check ${flakePath} --print-build-logs";

    # ---- Evaluate the current system configuration without building it
    ## Prints the system derivation path without building or activating
    neval =
      "nix eval ${flakePath}#${systemConfigurations}.${flakeHost}.config.system.build.toplevel.drvPath";

    # ---- Build the current system configuration without activation
    ## Builds the full system without creating a result link or switching generations
    rsafe =
      "sudo -H nix build ${flakePath}#${systemBuildTarget} --no-link";


    # ---------------------------------------------------------
    # ---- FLAKE COMMANDS ---- #
    # ---------------------------------------------------------

    # ---- Show the flake outputs
    ## Lists packages, applications, systems, and other exposed outputs
    nshow = "nix flake show ${flakePath}";

    # ---- Update the flake inputs
    ## Fetches the latest inputs and updates flake.lock
    "flake-update" = "nix flake update --flake ${flakePath}";
  };


  programs.fish.functions = {

    # ---------------------------------------------------------
    # ---- nvalidate -> Evaluate, build, and save the output ---- #
    #
    # Evaluates and then builds the current system without switching
    # generations or running activation.
    #
    # Works on:
    # macOS -> darwinConfigurations
    # Linux -> nixosConfigurations
    #
    # Both command outputs are shown in the terminal and saved in
    # the user's Downloads folder.
    # ---------------------------------------------------------

    nvalidate = ''
      function nvalidate --description "Evaluate and build the Nix system configuration with a Downloads log"

        # Current system configuration
        set -l flake_path "${flakePath}"
        set -l flake_host "${flakeHost}"

        # Output locations
        set -l downloads_dir "$HOME/Downloads"
        set -l timestamp (command date "+%Y-%m-%d-%H%M%S")
        set -l log_file "$downloads_dir/$timestamp-nix-eval.log"


        # Make sure the Downloads directory exists
        if not test -d "$downloads_dir"
          echo "Downloads folder does not exist: $downloads_dir" >&2
          return 1
        end


        # Select the current platform configuration
        if test (uname -s) = "Darwin"
          set -l configuration_type "darwinConfigurations"
          set -l build_target "$configuration_type.$flake_host.system"
        else
          set -l configuration_type "nixosConfigurations"
          set -l build_target "$configuration_type.$flake_host.config.system.build.toplevel"
        end


        echo "Writing validation output to:"
        echo "$log_file"

        begin
          echo "Nix system validation"
          echo "Started: "(command date "+%Y-%m-%d %H:%M:%S %Z")
          echo "Flake: $flake_path#$flake_host"
          echo "Configuration: $configuration_type.$flake_host"
          echo
          echo "=== Evaluating the system configuration ==="


          if not nix eval \
              "$flake_path#$configuration_type.$flake_host.config.system.build.toplevel.drvPath"

            echo "Evaluation failed. The system build was not started."
            false

          else
            echo
            echo "=== Building the system configuration without activation ==="

            sudo -H nix build \
              "$flake_path#$build_target" \
              --no-link
          end

        end 2>&1 | command tee "$log_file"


        set -l pipeline_status $pipestatus


        # Make sure tee successfully wrote the log
        if test $pipeline_status[2] -ne 0
          echo "Could not save the validation output to: $log_file" >&2
          return 1
        end


        # Return the validation/build command status
        return $pipeline_status[1]
      end
    '';

    # ---------------------------------------------------------


    # ---------------------------------------------------------
    # ---- pinflake -> Archive and protect flake inputs ---- #
    #
    # Fetches all inputs for a flake and creates indirect GC roots
    # so nix-collect-garbage does not remove them.
    #
    # Defaults to the configured Nix repository.
    #
    # Examples:
    #
    # pinflake
    # pinflake ~/.config/nix/nix-config
    # ---------------------------------------------------------

    pinflake = ''

      # Set the flake path to the default Nix configuration directory
      set -l flake_path "${flakePath}"


      # If an argument was supplied, use it instead
      if test (count $argv) -gt 0

        # Use the first argument as the flake path
        set flake_path "$argv[1]"
      end


      # Check if the specified directory contains a flake
      if not test -f "$flake_path/flake.nix"
        echo "Not a flake directory: $flake_path"

        # Return 1 to indicate an error occurred
        return 1
      end


      # Create a directory for the flake input GC roots
      set -l root_dir "$HOME/.local/state/nix/gcroots/flake-inputs"

      # Use command to bypass the global mkdir alias
      command mkdir -p "$root_dir"


      # Print the flake being archived
      echo "Archiving flake inputs from:"
      echo "$flake_path"


      # Archive the flake and return its input information as JSON
      set -l archive_json (
        nix flake archive --json "$flake_path"
      )

      # Stop if nix flake archive fails
      or begin
        echo "Failed to archive flake inputs."
        return 1
      end


      # Extract all Nix store paths from the archive output
      set -l store_paths (

        printf "%s" "$archive_json" |

        jq -r '
          [
            .path?,
            .storePath?,
            (
              .inputs? // {}

              | ..
              | objects

              | .path?, .storePath?
            )
          ]

          | flatten

          | map(
              select(
                type == "string"
                and startswith("/nix/store/")
              )
            )

          | unique
          | .[]
        '
      )


      # Make sure at least one input store path was returned
      if test (count $store_paths) -eq 0
        echo "No flake input store paths were returned."
        return 1
      end


      # Create a GC root for every input store path
      for store_path in $store_paths

        # Extract the store path name
        set -l store_name (basename "$store_path")

        # Build the GC root path
        set -l root_path "$root_dir/$store_name"

        # Remove any existing root to avoid conflicts
        command rm -f "$root_path"


        # Realise the store path and create an indirect GC root
        nix-store \
          --realise "$store_path" \
          --add-root "$root_path" \
          --indirect >/dev/null


        # Stop if the input could not be pinned
        or begin
          echo "Failed to pin: $store_path"
          return 1
        end


        # Print the successfully pinned path
        echo "Pinned: $store_path"
      end


      # Print completion information
      echo
      echo "Flake inputs protected from garbage collection."
      echo "GC roots: $root_dir"
    '';

    # ---------------------------------------------------------
    };
  };
}
