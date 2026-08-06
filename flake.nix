# /Users/ven/.config/nix/nix-config/flake.nix
#
# ==========================================================
# FLAKE: MAIN ENTRYPOINT
# - Provides nix-darwin configuration "macbook"
# - Integrates Home Manager via darwin/default.nix
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

    # Flake module framework
    flake-parts.url = "github:hercules-ci/flake-parts";

    # AstroNvim (managed as config)
    astronvim = {
      url = "github:AstroNvim/template";
      flake = false;
    };

    # Codex extension sources are pinned in flake.lock and assembled locally.
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };

    simple-english = {
      url = "github:AminBlg/SimpleEnglish";
      flake = false;
    };

    codebase-memory-mcp = {
      url = "github:DeusData/codebase-memory-mcp";
      flake = false;
    };
  };

  outputs =
    inputs@{
      flake-parts,
      ...

    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Build flake package outputs for the current Darwin platform.
      systems = [ "aarch64-darwin" ];

      imports = [
        ./flake-modules/packages.nix
        ./flake-modules/macbook.nix
      ];
    };

}
