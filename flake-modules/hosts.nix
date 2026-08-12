# flake-modules/hosts.nix
#
# =====================================================================
# FLAKE: SHARED HOST BUILDING BLOCKS
#
# Exposes the shared terminal Home Manager module and constructors for
# future Linux Home Manager and NixOS hosts without defining a machine.
# =====================================================================

{ inputs, ... }:

{
  # ---- HOME MANAGER FLAKE-PARTS OPTIONS ---- #
  # Provides typed flake.homeModules and flake.homeConfigurations options.
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake = {
    # ---- SHARED TERMINAL HOME MODULE ---- #
    # Future host modules import this and choose terminal features locally.
    homeModules.sharedTerminal = {
      imports = [
        ../shared/terminal
        ../shared/terminal/nvim
        ../shared/terminal/cli-tuis
      ];
    };

    # ---- MACHINE-NEUTRAL CONSTRUCTORS ---- #
    lib = {
      # Creates a standalone Home Manager configuration for a future Linux host.
      # Callers supply system, user-specific modules, and optional Nixpkgs config.
      mkStandaloneHome =
        {
          system,
          modules,
          extraSpecialArgs ? { },
          nixpkgsConfig ? { },
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          };

          # Lets imported Home Manager modules use the same package set
          # without resolving it indirectly through the module fixpoint.
          homeSpecialArgs = extraSpecialArgs // { inherit pkgs; };
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit modules pkgs;
          extraSpecialArgs = homeSpecialArgs;
        };

      # Creates a NixOS system for a future host with only caller-supplied facts.
      # Set homeManagerModule when that machine integrates Home Manager as NixOS.
      mkNixosHost =
        {
          system,
          modules,
          extraSpecialArgs ? { },
          nixpkgsConfig ? { },
          homeManagerModule ? null,
        }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = extraSpecialArgs;

          modules =
            modules
            ++ [
              # Gives callers a low-priority shared Nixpkgs configuration.
              ({ lib, ... }: {
                nixpkgs.config = lib.mkDefault nixpkgsConfig;
              })
            ]
            ++ inputs.nixpkgs.lib.optional (
              homeManagerModule != null
            ) inputs.home-manager.nixosModules.home-manager
            ++ inputs.nixpkgs.lib.optional (homeManagerModule != null) homeManagerModule;
        };
    };
  };
}
