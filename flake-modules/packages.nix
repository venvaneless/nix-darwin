# flake-modules/packages.nix
#
# =====================================================================
# FLAKE PACKAGES
#
# Exposes locally packaged macOS applications as first-class flake
# packages. This makes each derivation addressable with:
#
#   nix build .#<package>
#   nix-update <package> --flake
# =====================================================================

{ inputs, ... }:

let
  # ---- Variables from options/default.nix
  # The nixpkgs policy is defined once there and read by every machine.
  inherit (import ../options { }) nixpkgsConfig;
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;

        config = nixpkgsConfig;
      };
    in
    {
      # Uses the same policy as every host when evaluating packages
      # directly through this flake.
      _module.args.pkgs = pkgs;

      packages = {
        assetsnap = pkgs.callPackage ../darwin/packages/assetsnap.nix { };

        better-finder-attributes = pkgs.callPackage ../darwin/packages/better-finder-attributes.nix { };

        better-finder-rename = pkgs.callPackage ../darwin/packages/better-finder-rename.nix { };

        hammerspoon = pkgs.callPackage ../darwin/packages/hammerspoon.nix { };

        update-hammerspoon = pkgs.callPackage ../darwin/packages/hammerspoon-update.nix { };

        iterm2 = pkgs.callPackage ../darwin/packages/iterm2 { };

        iterm-ai-plugin = pkgs.callPackage ../darwin/packages/iterm2/iterm-ai-plugin.nix { };

        iterm-browser-plugin = pkgs.callPackage ../darwin/packages/iterm2/iterm-browser-plugin.nix { };

        the-unarchiver = pkgs.callPackage ../darwin/packages/unarchiver { };

        update-unarchiver = pkgs.callPackage ../darwin/packages/unarchiver/unarchiver-update.nix { };
      };
    };
}
