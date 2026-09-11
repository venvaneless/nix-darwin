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

  paths = import ../options/paths.nix { };

  # ---- Variables from options/default.nix
  # Creates the vocabulary for configuring Nix and translates it into
  # nix.settings. It holds no value of its own and switches nothing on.
  #
  # Passed as a module path so the module system supplies its config and
  # lib arguments instead of this file resolving them.
  nixOptions = (import ../options { }).nixOptions;

  # ---- SHARED NIX CONFIGURATION ---- #
  # The values every machine gets. A machine takes precedence over a
  # scalar, and adds to a list, by naming it in its own default.nix.
  #
  # ** Standalone Home Manager receives neither: trusted-users is only
  # ** honoured in the system-level nix.conf, and flakes have to be enabled
  # ** before `home-manager switch --flake` can run at all.
  nixConfiguration = ../shared/nix-options.nix;

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
          inherit system;

          inherit specialArgs;

          modules = [
            # Provides SOPS secret management.
            inputs.sops-nix.darwinModules.sops

            # Nix's options, then the values every machine gets.
            nixOptions
            nixConfiguration
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

          # Shared option values are loaded once by host construction and
          # supplied to the module graph as custom arguments, the way
          # flake-modules/macbook.nix supplies them on Darwin.
          sharedOptions = import ../options {
            inherit inputs pkgs;
          };
          inherit (sharedOptions) serviceOptions terminalOptions obsidianOptions unstablePkgs;

          platforms = import ../options/platforms.nix { inherit pkgs; };
          packageOptions = import ../options/package-options.nix {
            lib = inputs.nixpkgs.lib;
            inherit paths platforms pkgs;
            installTarget = "home";
          };

          # Lets imported Home Manager modules use the same package set
          # without resolving it indirectly through the module fixpoint.
          homeSpecialArgs = extraSpecialArgs // {
            inherit
              packageOptions
              paths
              pkgs
              platforms
              serviceOptions
              terminalOptions
              obsidianOptions
              unstablePkgs
              ;
          };
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
      # Standalone Home Manager remains a separate flake output.
      mkNixosHost =
        {
          system,
          modules,
          specialArgs ? { },
          nixpkgsConfig ? sharedNixpkgsConfig,
        }:
        let
          # Built here only so the shared helpers below can be evaluated
          # before the module fixpoint exists. The host's own package set is
          # still built by the NixOS module system from the same policy.
          hostPkgs = import inputs.nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          };

          # Shared option values are loaded once by host construction and
          # supplied to the module graph as custom arguments.
          sharedOptions = import ../options {
            inherit inputs;
            pkgs = hostPkgs;
          };
          inherit (sharedOptions) serviceOptions unstablePkgs;

          platforms = import ../options/platforms.nix { pkgs = hostPkgs; };
          packageOptions = import ../options/package-options.nix {
            lib = inputs.nixpkgs.lib;
            inherit paths platforms;
            pkgs = hostPkgs;
            installTarget = "system";
          };

          # nixosSystem accepts specialArgs and silently ignores every
          # argument it does not know, so anything a module expects has to
          # be merged in here. pkgs is deliberately absent: NixOS supplies
          # it from the module system, built with the policy below.
          hostSpecialArgs = specialArgs // {
            inherit
              packageOptions
              paths
              platforms
              serviceOptions
              unstablePkgs
              ;
          };
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = hostSpecialArgs;

          modules =
            [
              # Provides SOPS secret management.
              inputs.sops-nix.nixosModules.sops

              # Nix's options, then the values every machine gets.
              nixOptions
              nixConfiguration
            ]
            ++ modules
            ++ [
              # Gives callers a low-priority shared Nixpkgs configuration.
              ({ lib, ... }: {
                nixpkgs.config = lib.mkDefault nixpkgsConfig;
              })
            ]
            ;
        };
    };
  };
}
