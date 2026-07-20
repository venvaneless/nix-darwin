# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/nix-aliases.nix
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
      set -l flake_path "${flakePath}"

      if test (count $argv) -gt 0
        set flake_path "$argv[1]"
      end

      if not test -f "$flake_path/flake.nix"
        echo "Not a flake directory: $flake_path"
        return 1
      end

      set -l root_dir "$HOME/.local/state/nix/gcroots/flake-inputs"

      # Use command to bypass the global mkdir alias.
      command mkdir -p "$root_dir"

      echo "Archiving flake inputs from:"
      echo "$flake_path"

      set -l archive_json (
        nix flake archive --json "$flake_path"
      )

      or begin
        echo "Failed to archive flake inputs."
        return 1
      end

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

      if test (count $store_paths) -eq 0
        echo "No flake input store paths were returned."
        return 1
      end

      for store_path in $store_paths
        set -l store_name (basename "$store_path")
        set -l root_path "$root_dir/$store_name"

        command rm -f "$root_path"

        nix-store \
          --realise "$store_path" \
          --add-root "$root_path" \
          --indirect >/dev/null

        or begin
          echo "Failed to pin: $store_path"
          return 1
        end

        echo "Pinned: $store_path"
      end

      echo
      echo "Flake inputs protected from garbage collection."
      echo "GC roots: $root_dir"
    '';
    # ---------------------------------------------------------
  };
 }