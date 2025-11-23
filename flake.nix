# /Users/ven/dotfiles/nix/flake.nix
{
  description = "Ven’s setup";

  nixConfig = {
    allow-dirty = true;
  };

  inputs = {
    nixpkgs.url        = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url         = "github:LnL7/nix-darwin";
    home-manager.url   = "github:nix-community/home-manager";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url   = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager, nix-homebrew, ... }:
  let
    system = "aarch64-darwin"; # Change to linux if you need Linux support
    pkgs   = import nixpkgs { inherit system; };
  in
  {
    # --- macOS system configuration (nix-darwin) ---
    darwinConfigurations.macbook = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs nix-homebrew home-manager; };
      modules = [
        ./darwin/index.nix  # Import your index.nix here
      ];
    };

    # --- Flake apps ---
    # apps.${system} = { };
  };
}
