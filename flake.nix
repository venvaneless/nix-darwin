# /Users/ven/.config/nix/nix-config/flake.nix
#
# ==========================================================
# FLAKE: MAIN ENTRYPOINT
# - Provides nix-darwin configuration "macbook"
# - Integrates Home Manager via darwin/nix-darwin.nix
# ==========================================================

{
  description = "Ven’s setup";

  # Allow committing even with build artefacts like ./result
  nixConfig.allow-dirty = true;

  inputs = {

    # Core package set
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # nix-darwin
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Unstable branch
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew (FIXED)
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # NEW: flake utilities
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # AstroNvim (managed as config)
    astronvim = {
      url = "github:AstroNvim/template";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      nix-homebrew,
      flake-utils,
      flake-parts,
      ...

    }:
    let
      system = "aarch64-darwin";

      # Load the list of overlays from:
      macbookOverlays = import ./darwin/modules/overlays;

    in
    {

      # =====================================================================
      # NIXPKGS OVERLAYS (modular, imported from overlays/)
      # =====================================================================
      overlays.macbook = nixpkgs.lib.composeManyExtensions macbookOverlays;

      # DARWIN: MAIN SYSTEM
      # =========================
      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit inputs nix-homebrew home-manager;
        };

        modules = [
          {
            nixpkgs.overlays = [
              self.overlays.macbook
            ];
          }

          ./darwin/nix-darwin.nix
        ];
      };

      # No standalone Home Manager (only via darwin)
      homeConfigurations = { };

      # No flake apps yet
      apps.${system} = { };

      # devShells.${system}.default =
      #  nixpkgs.legacyPackages.${system}.mkShell {};
    };

}
