# flake-modules/macbook.nix
#
# =====================================================================
# DARWIN HOST: MACBOOK
#
# Defines the macbook-specific nix-darwin configuration and connects it
# to the flake-parts package outputs for the matching platform.
# =====================================================================

{
  inputs,
  withSystem,
  ...
}:

let
  system = "aarch64-darwin";

  # ---- Variables from options/default.nix
  # The nixpkgs policy is defined once there and read by every machine.
  inherit (import ../options { }) nixpkgsConfig;

  # Load the list of overlays from darwin/overlays.
  macbookOverlays = import ../darwin/overlays;

  macbookOverlay = inputs.nixpkgs.lib.composeManyExtensions macbookOverlays;

  # Provide the fully configured package set as a module special argument.
  # This keeps shared package-list helpers independent of the module fixpoint.
  macbookPkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
    overlays = [ macbookOverlay ];
  };
in
{
  # =====================================================================
  # NIXPKGS OVERLAYS (modular, imported from darwin/overlays/)
  # =====================================================================
  flake.overlays.macbook = macbookOverlay;

  # =====================================================================
  # DARWIN: MAIN SYSTEM
  # =====================================================================
  flake.darwinConfigurations.macbook =
    withSystem system (
      { ... }:
      inputs.darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit inputs;
          pkgs = macbookPkgs;
          home-manager = inputs.home-manager;
          nix-homebrew = inputs.nix-homebrew;

        };

        modules = [
          {
            nixpkgs.overlays = [ macbookOverlay ];

            # The same imported policy, also set as a module option so
            # anything reading config.nixpkgs.* sees it too. This is what
            # shared/hosts.nix used to provide.
            nixpkgs.config = nixpkgsConfig;
          }

          # Provides SOPS secret management
          inputs.sops-nix.darwinModules.sops

          ../darwin/default.nix
        ];
      }
    );
}
