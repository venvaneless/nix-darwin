# /Users/ven/.config/nix/nix-darwin/flake.nix
#
# FLAKE: MAIN ENTRYPOINT
# =========================
# - Provides nix-darwin configuration "macbook"
# - Integrates Home Manager via darwin/index.nix

{
  description = "Ven’s setup";

  # Allow committing even with build artefacts like ./result
  nixConfig.allow-dirty = true;

  inputs = {
    # Core package set
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # nix-darwin
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.inputs.darwin.follows = "darwin";
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, nix-homebrew, ... }:
    let
      system = "aarch64-darwin";
    in {
      # DARWIN: MAIN SYSTEM
      # =========================
      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit inputs nix-homebrew home-manager;
        };

        modules = [
          ./darwin/index.nix
        ];
      };

      # No standalone Home Manager (only via darwin)
      homeConfigurations = {};

      # No flake apps yet
      apps.${system} = {};
    };
}
