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
{config, inputs, ...}: let
  # ---- SHARED NIXPKGS POLICY ---- #
  # Package outputs need this before any Nix module graph exists.
  sharedNixpkgsConfig = config.flake.lib.sharedNixpkgsConfig;
  paths = import ../options/paths.nix { };
in {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;

      config = sharedNixpkgsConfig;
    };
    platforms = import ../options/platforms.nix { inherit pkgs; };
    packageOptions = import ../options/package-options {
      lib = inputs.nixpkgs.lib;
      installTarget = "system";
      inherit paths pkgs platforms;
    };
    darwinPackages = packageOptions.darwinPackages;
  in {
    # Uses the same policy as every host when evaluating packages
    # directly through this flake.
    _module.args.pkgs = pkgs;

    # ---- DARWIN-ONLY APPLICATION PACKAGES ---- #
    # Every derivation below packages a macOS application bundle, so it
    # is exposed on the Darwin system only. x86_64-linux is listed in
    # flake.nix for the NixOS host outputs, and would fail to evaluate
    # these.
    packages = inputs.nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      assetsnap = darwinPackages.assetsnap;

      better-finder-attributes = darwinPackages.betterFinderAttributes;

      better-finder-rename = darwinPackages.betterFinderRename;

      hammerspoon = darwinPackages.hammerspoon;

      update-hammerspoon = darwinPackages.updateHammerspoon;

      iterm-ai-plugin = darwinPackages.itermAiPlugin;

      iterm-browser-plugin = darwinPackages.itermBrowserPlugin;

    };
  };
}
