# /Users/ven/.config/nix/nix-darwin/flake.nix
#
# FLAKE: MAIN ENTRYPOINT
# ================================================
# Provides:
#   - nix-darwin system configuration (macbook)
#   - Integrated Home Manager configuration (via index.nix)
# ================================================

{
  description = "Ven’s setup";

  # Allow committing without cleaning build artifacts
  nixConfig.allow-dirty = true;

  # ------------------------------------------------------------
  # --- INPUTS ---
  # ------------------------------------------------------------
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url       = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # HM follows nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # ------------------------------------------------------------
  # 
  # --- OUTPUTS
  # ------------------------------------------------------------
  outputs = inputs@{ nixpkgs, darwin, home-manager, nix-homebrew, ... }:
  let
    system = "aarch64-darwin";
    pkgs   = import nixpkgs { inherit system; };
  in
  {
    # --- nix-darwin SYSTEM ---
    darwinConfigurations.macbook = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs nix-homebrew home-manager; };
      modules = [
        ./darwin/index.nix
      ];
    };

    # --- No standalone home-manager
    # ------------------------------------------------------------
    homeConfigurations = {};

    # --- FLAKE APPS ---
    # ------------------------------------------------------------
    apps.${system} = {};
  };
}
