# /Users/ven/dotfiles/nix/flake.nix
#
# FLAKE: MAIN ENTRYPOINT
# ================================================
# Provides:
#   - nix-darwin system configuration (macbook)
#   - Standalone Home Manager configuration (#ven)
#
# Structure:
#   macbook → full system + integrated Home Manager
#   ven     → standalone Home Manager switch
#
# Notes:
#   - home-manager.nix is for integrated HM
#   - home-manager-standalone.nix is for standalone HM
#   - No system options should appear in either HM file
# ================================================


{
  description = "Ven’s setup";

  # Allow committing without cleaning build artifacts
  nixConfig.allow-dirty = true;


  # ------------------------------------------------------------
  # 
  # --- INPUTS
  # ------------------------------------------------------------
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url       = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # --- Home Manager nixpkgs
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # ------------------------------------------------------------
  # 
  # --- OUTPUTS
  # ------------------------------------------------------------
  # 
  # ---Nix Darwin ---
  outputs = inputs@{ nixpkgs, darwin, home-manager, nix-homebrew, ... }:
  let
    system = "aarch64-darwin";
    pkgs   = import nixpkgs { inherit system; };
  in

  {
    # ------------------------------------------------------------
    # 
    # --- darwin Configurations - system ---
    darwinConfigurations.macbook = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs nix-homebrew home-manager; };
      modules = [
        ./darwin/index.nix
        # Imports all modules
      ];
    };


    # ------------------------------------------------------------
    # 
    # --- HOME MANAGER: Standalone Configuration ---
    homeConfigurations.ven = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs nix-homebrew home-manager; };
      modules = [
        ./darwin/modules/system/home-manager-standalone.nix
        # Imports HM for the system
      ];
    };


    # ------------------------------------------------------------
    # 
    # --- FLAKE APPS (disabled for now)
    # ------------------------------------------------------------
    apps.${system} = {};
  };
}
