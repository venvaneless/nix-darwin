# flake-modules/hosts.nix
#
# =====================================================================
# FLAKE: SHARED HOST BUILDING BLOCKS
#
# Exposes the shared terminal Home Manager module and constructors for
# Darwin, Linux Home Manager, and NixOS hosts without defining a machine.
# =====================================================================

{ inputs, ... }:

let
  # ---- Variables from options/default.nix
  # The nixpkgs policy is defined once there, so a host that does not
  # override it still matches the rest. Bound under a different name
  # than the constructor arguments below, which would shadow it.
  sharedNixpkgsConfig = (import ../options { }).nixpkgsConfig;
in
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
      # Creates a nix-darwin system with the shared SOPS module included.
      # Callers supply the host facts, package set, and system modules.
      mkDarwinHost =
        {
          system,
          modules,
          specialArgs ? { },
        }:
        inputs.darwin.lib.darwinSystem {
          inherit system specialArgs;

          modules = [
            # Provides SOPS secret management.
            inputs.sops-nix.darwinModules.sops
          ] ++ modules;
        };

      # Creates a standalone Home Manager configuration for a future Linux host.
      # Callers supply system, user-specific modules, and optional Nixpkgs config.
      mkStandaloneHome =
        {
          system,
          modules,
          extraSpecialArgs ? { },
          nixpkgsConfig ? sharedNixpkgsConfig,
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
          inherit pkgs;
          extraSpecialArgs = homeSpecialArgs;

          # Provides user-level SOPS secret management for every standalone
          # Home Manager host built through this shared constructor.
          modules = [
            # Provides SOPS secret management.
            inputs.sops-nix.homeManagerModules.sops
          ] ++ modules;
        };

      # Creates a NixOS system for a future host with only caller-supplied facts.
      # Set homeManagerModule when that machine integrates Home Manager as NixOS.
      mkNixosHost =
        {
          system,
          modules,
          extraSpecialArgs ? { },
          nixpkgsConfig ? sharedNixpkgsConfig,
          homeManagerModule ? null,
        }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = extraSpecialArgs;

          modules =
            [
              # Provides SOPS secret management.
              inputs.sops-nix.nixosModules.sops
            ]
            ++ modules
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
