# flake-modules/hosts.nix
#
# =====================================================================
# FLAKE: SHARED HOST BUILDING BLOCKS
#
# Declares the flake's external dependencies and exposes shared terminal
# Home Manager modules and constructors without defining a machine.
# =====================================================================

let
  # ---- EXTERNAL DEPENDENCIES ---- #
  flakeInputs = {
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

    # SOPS secret management for Darwin, standalone Home Manager, and NixOS
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

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

    claude-mem = {
      url = "github:thedotmack/claude-mem";
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

    scholarbrain = {
      url = "github:SHzzzAyys/scholarbrain/feat/deepseek-pubmed-arxiv";
      flake = false;
    };

    # WezTerm plugins are pinned in flake.lock and deployed by
    # shared/terminal/wezterm/wez-plugins.nix, so `nix flake update`
    # updates them together with every other input.
    wezterm-resurrect = {
      url = "github:MLFlexer/resurrect.wezterm";
      flake = false;
    };

    wezterm-tabline = {
      url = "github:michaelbrusegard/tabline.wez";
      flake = false;
    };

    wezterm-sessions = {
      url = "github:abidibo/wezterm-sessions";
      flake = false;
    };

    wezterm-smart-workspace-switcher = {
      url = "github:MLFlexer/smart_workspace_switcher.wezterm";
      flake = false;
    };
  };
in
{
  # Read by flake.nix before flake-parts evaluates this module.
  inputs = flakeInputs;

  # The flake-parts module consumed by flake.nix.
  flakeModule =
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
    };
}
