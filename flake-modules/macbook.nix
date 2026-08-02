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

  # Load the list of overlays from darwin/overlays.
  macbookOverlays = import ../darwin/overlays;

  macbookOverlay = inputs.nixpkgs.lib.composeManyExtensions macbookOverlays;
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
      { config, ... }:
      inputs.darwin.lib.darwinSystem {
        inherit system;

        specialArgs = {
          inherit inputs;
          home-manager = inputs.home-manager;
          nix-homebrew = inputs.nix-homebrew;
          venPackages = config.packages;
        };

        modules = [
          {
            nixpkgs.overlays = [ macbookOverlay ];
          }

          ../darwin/default.nix
        ];
      }
    );
}
