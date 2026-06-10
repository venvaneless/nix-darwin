# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/nix-aliases.nix
#
# NIX-DARWIN ALIASES
# ===========================================

{ ... }:

let
  flakePath = "/Users/ven/.config/nix/nix-config";
  flakeHost = "macbook";
in
{
  programs.fish.shellAliases = {

    # ---- Evaluate and build derivations / Switch flake config
    # Switches to the current 
    drs = "sudo -H darwin-rebuild switch --flake ${flakePath}#${flakeHost}";
    
    # ---- Validate the flake and configuration structure 
    ncheck = "nix flake check ${flakePath}";

    # ---- Same as "ncheck" but with logs
    "nl-check" = "nix flake check ${flakePath} --print-build-logs";
    
    # ---- Safely validate if the system can evaluate/build
    rsafe = "sudo -H nix build ${flakePath}#darwinConfigurations.${flakeHost}.system --no-link";

    # ---- Evaluate and build the flake (No switch)
     drb = "sudo -H darwin-rebuild build --flake ${flakePath}#${flakeHost}";
    
    # ---- Analyse the configuration for bugs and syntax errors
    rcheck = "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}";

    # ---- Show the flake configuration
    nshow = "nix flake show ${flakePath}";

    # ---- Recreate / update flake's lock file
    "nix-update" = "nix flake update --flake ${flakePath}";
  };
}