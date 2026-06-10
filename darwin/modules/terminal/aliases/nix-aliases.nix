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
	  # ------------------------------------------------------------
    # ---- Evaluate the flake
    # Builds all derivations
    # Doesn't switch to the current flake
    # ------------------------------------------------------------
    drb = "sudo -H darwin-rebuild build --flake ${flakePath}#${flakeHost}";

    # ------------------------------------------------------------
    # ---- Evaluate and build derivations
    # Switches to the current flake config
    # ------------------------------------------------------------
    drs = "sudo -H darwin-rebuild switch --flake ${flakePath}#${flakeHost}";

    # ------------------------------------------------------------
    # ---- Check the nix-darwin system configuration
    # Analyses for bugs and syntax errors
    # No rebuilding/applying
    # ------------------------------------------------------------
    rcheck = "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}";

    # ------------------------------------------------------------
    # Check the flake structure, NOT only the Darwin configuration
    # ------------------------------------------------------------
    ncheck = "nix flake check ${flakePath}";

    # ------------------------------------------------------------
    # Shows the flake configuration
    # ------------------------------------------------------------
    nshow = "nix flake show ${flakePath}";

    # ------------------------------------------------------------
    # Safely check nix configuration
    rsafe = "sudo -H nix build ${flakePath}#darwinConfigurations.${flakeHost}.system --no-link";
    # ------------------------------------------------------------

    # ------------------------------------------------------------
    # Recreates / updates the lock file of the flake
    # ------------------------------------------------------------
    "nix-update" = "nix flake update --flake ${flakePath}";
  };
}