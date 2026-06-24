# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/nix-aliases.nix
# 
# =====================================================================
# NIX-DARWIN: ALIASES
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
}