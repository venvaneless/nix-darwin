# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/flakehost-aliases.nix
#
# ============================================================
# NIX PATH ALIASES
# ============================================================

{ ... }:

let
  flakePath = "/Users/ven/.config/nix/nix-config";
  flakeHost = "macbook";
in
{
  programs.fish.shellAliases = {
    ncfg = "cd ${flakePath}";
    nscripts = "cd /Users/ven/.config/nix/nix-scripts";

    drs = "sudo -H darwin-rebuild switch --flake ${flakePath}#${flakeHost}";
    drb = "sudo -H darwin-rebuild build --flake ${flakePath}#${flakeHost}";
    rcheck = "sudo -H darwin-rebuild check --flake ${flakePath}#${flakeHost}";
    ncheck = "nix flake check ${flakePath}";
  };
}