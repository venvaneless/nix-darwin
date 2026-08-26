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

  # Shared host definitions also provide the external dependency set.
  inputs = (import ./flake-modules/hosts.nix).inputs;

  outputs =
    inputs@{
      flake-parts,
      ...

    }:
    let
      hosts = import ./flake-modules/hosts.nix;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Governs current per-system Darwin package outputs. Linux and NixOS
      # host outputs and modules are defined separately in flake-modules/.
      systems = [ "aarch64-darwin" ];

      imports = [
        # ---- SHARED BUILDING BLOCKS ---- #
        ./flake-modules/packages.nix
        hosts.flakeModule

        # ---- ONE FILE PER MACHINE ---- #
        # macbook   : Apple Silicon MacBook, nix-darwin
        # linux     : ROG Zephyrus
        # imac-nix  : 2015 Intel iMac, NixOS
        ./flake-modules/macbook.nix
        ./flake-modules/linux.nix
        ./flake-modules/imac-nix.nix
      ];
    };

}
