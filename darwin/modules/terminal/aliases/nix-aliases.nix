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
    # -------------------------------------
    # Evaluates the flake
    # Builds all derivations
    # Doesn't switch to the current flake
    # -------------------------------------
    drb = "sudo -H darwin-rebuild build --flake ${flakePath}#${flakeHost}";

    # -------------------------------------
    # Evaluates the flake
    # Builds all derivations
    # Switches to the current flake config
    # -------------------------------------
    drs = "sudo -H darwin-rebuild switch --flake ${flakePath}#${flakeHost}";

    # -------------------------------------
    # Checks the full nix-darwin system configuration
    # Analyses for bugs and syntax errors
    # No rebuilding/applying
    # -------------------------------------
    drc = "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}";

    # ------------------------------------------------------------
    # Checks the flake itself, NOT only the Darwin configuration
    # ------------------------------------------------------------
    ndc = "nix flake check ${flakePath}";

    # -------------------------------------------------
    # Recreates / updates the lock file of the flake
    # -------------------------------------------------
    ndl = "nix flake update --flake ${flakePath}";

    # ------------------------------------
    # Updates flake inputs
    # ------------------------------------
    ndu = "nix flake update --flake ${flakePath}";
  };
}