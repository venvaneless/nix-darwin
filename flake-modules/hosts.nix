# flake-modules/hosts.nix
#
# =====================================================================
# FLAKE: SHARED HOST BUILDING BLOCKS
#
# Exposes the shared Home Manager module and constructors for
# Darwin, Linux Home Manager, and NixOS hosts without defining a machine.
# =====================================================================
{ inputs, ... }:
let
  # ---- SHARED OPTION CONTEXT ---- #
  # This is the one plain import used before a module fixpoint exists. It
  # provides the pre-evaluation values and the module paths; it does not
  # import those modules into every host by itself.
  sharedOptionValues = import ../options { };
  inherit (sharedOptionValues)
    nixSharedSettings
    qbittorrentOptions
    sharedPackageOptions
    vscodeOptions
    ;
  sharedNixpkgsConfig = sharedOptionValues.nixpkgsConfig;

  # ---- PER-HOST SHARED CONTEXT ---- #
  # Every constructor receives a package set for one host. Build the values
  # that depend on that package set once here, then pass the same context to
  # that host's Nix module graph.
  mkHostContext =
    {
      pkgs,
      installTarget,
    }:
    let
      sharedOptions = import ../options { inherit inputs pkgs; };
      inherit (sharedOptions)
        paths
        serviceOptions
        containerBackupOptions
        terminalOptions
        weztermOptions
        cliOptions
        envSettingsOptions
        espansoOptions
        vscodeOptions
        qbittorrentOptions
        sharedHomeModule
        unstablePkgs
        ;

      platforms = import ../options/platforms.nix { inherit pkgs; };
      packageOptions = (import ../options/package-options { mode = "helper"; }) {
        lib = inputs.nixpkgs.lib;
        inherit
          paths
          platforms
          pkgs
          installTarget
          ;
      };
      darwinPackages = packageOptions.darwinPackages;

    in
    {
      inherit
        cliOptions
        containerBackupOptions
        darwinPackages
        envSettingsOptions
        espansoOptions
        packageOptions
        paths
        pkgs
        platforms
        serviceOptions
        sharedHomeModule
        sharedOptions
        terminalOptions
        unstablePkgs
        vscodeOptions
        weztermOptions
        qbittorrentOptions
        ;
    };
in
{
  # ---- HOME MANAGER FLAKE-PARTS OPTIONS ---- #
  # Provides typed flake.homeModules and flake.homeConfigurations options.
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  flake = {
    # ---- SHARED HOME MODULE ---- #
    # Values every Home Manager host uses, integrated on Darwin and
    # standalone on Linux. Its implementation is supplied by the shared
    # context, so consumers never need its literal path.
    homeModules."shared.home" = { espansoOptions, sharedHomeModule, ... }: {
      imports = [
        espansoOptions
        sharedHomeModule
      ];
    };

    # ---- SHARED ENVIRONMENT HOME MODULE ---- #
    # Every Home Manager host gets the common environment option module
    # and its shared knob assignments through this one composition point.
    homeModules."shared.environment" = { envSettingsOptions, ... }: {
      imports = [
        envSettingsOptions
        ../shared/env-settings.nix
      ];
    };

    # ---- SHARED SERVICES HOME MODULE ---- #
    # Declares shared Home Manager service options once for every host.
    homeModules."shared.services" = { serviceOptions, ... }: {
      imports = [
        serviceOptions
      ];
    };

    # ---- SHARED TERMINAL HOME MODULE ---- #
    # Every Home Manager host imports this and chooses terminal features locally.
    homeModules."shared.terminal" = {
      cliOptions,
      terminalOptions,
      ...
    }: {
      imports = [
        # Terminal option modules declare values used by terminal modules.
        terminalOptions

        # CLI option modules define the knobs set by shared/terminal/cli-tuis.
        cliOptions
        ../shared/terminal
        ../shared/terminal/nvim
        ../shared/terminal/cli-tuis
      ];
    };

    # ---- SHARED WEZTERM HOME MODULE ---- #
    # Keeps WezTerm's option declarations, Lua renderers, and shared knobs
    # behind one named Home Manager module boundary.
    homeModules."shared.terminal.wezterm" = { weztermOptions, ... }: {
      imports = [
        weztermOptions
        ../shared/terminal/wezterm
      ];
    };

    # ---- MACHINE-NEUTRAL CONSTRUCTORS ---- #
    lib = {
      # Lets host modules construct their configured package set from the
      # same shared nixpkgs policy without importing the option module.
      inherit mkHostContext sharedNixpkgsConfig;

      # Creates a nix-darwin system with the shared SOPS module included.
      # Callers supply the host facts, package set, and system modules.
      mkDarwinHost =
        {
          system,
          modules,
          specialArgs ? { },

          # Darwin hosts supply their fully configured package set so this
          # shared constructor can derive platform and package helpers once.
          # A host that already built its context passes it instead.
          hostContext ? mkHostContext {
            pkgs = specialArgs.pkgs or (throw "mkDarwinHost requires specialArgs.pkgs");
            installTarget = "system";
          },
        }:
        inputs.darwin.lib.darwinSystem {
          inherit system;

          specialArgs = specialArgs // hostContext;

          modules = [
            # Provides SOPS secret management.
            inputs.sops-nix.darwinModules.sops

            # Shared Nix settings and shared package options.
            nixSharedSettings
            sharedPackageOptions
            vscodeOptions
            qbittorrentOptions

            # Home Manager is a separate module graph, so it does not
            # inherit nix-darwin's specialArgs. Pass the host context at
            # this construction boundary; omit pkgs because Home Manager
            # already receives the configured global package set.
            {
              home-manager.extraSpecialArgs =
                (builtins.removeAttrs hostContext [
                  "darwinPackages"
                  "pkgs"
                ])
                // {
                  inherit inputs;
                };
            }
          ]
          ++ modules;
        };

      # Creates a standalone Home Manager configuration for a future Linux host.
      # Callers supply system, user-specific modules, and optional Nixpkgs config.
      mkStandaloneHome =
        {
          system,
          modules,
          extraSpecialArgs ? { },
          hostNixpkgsConfig ? sharedNixpkgsConfig,
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = hostNixpkgsConfig;
          };

          hostContext = mkHostContext {
            inherit pkgs;
            installTarget = "home";
          };

          # Lets imported Home Manager modules use the same package set
          # without resolving it indirectly through the module fixpoint.
          homeSpecialArgs = extraSpecialArgs // hostContext;
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = homeSpecialArgs;

          # Provides user-level SOPS secret management for every standalone
          # Home Manager host built through this shared constructor.
          modules = [
            # Provides SOPS secret management.
            inputs.sops-nix.homeManagerModules.sops
          ]
          ++ modules;
        };

      # Creates a NixOS system for a future host with only caller-supplied facts.
      # Standalone Home Manager remains a separate flake output.
      mkNixosHost =
        {
          system,
          modules,
          specialArgs ? { },
          hostNixpkgsConfig ? sharedNixpkgsConfig,
        }:
        let
          # Built here only so the shared helpers below can be evaluated
          # before the module fixpoint exists. The host's own package set is
          # still built by the NixOS module system from the same policy.
          hostPkgs = import inputs.nixpkgs {
            inherit system;
            config = hostNixpkgsConfig;
          };

          hostContext = mkHostContext {
            pkgs = hostPkgs;
            installTarget = "system";
          };

          # NixOS supplies its own pkgs through the module system. Do not
          # shadow it with the package set used only to build this context.
          nixosHostContext = builtins.removeAttrs hostContext [ "pkgs" ];

          # nixosSystem accepts specialArgs and silently ignores every
          # argument it does not know, so anything a module expects has to
          # be merged in here. pkgs is deliberately absent: NixOS supplies
          # it from the module system, built with the policy below.
          hostSpecialArgs = specialArgs // nixosHostContext;
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = hostSpecialArgs;

          modules = [
            # Provides SOPS secret management.
            inputs.sops-nix.nixosModules.sops

            # Shared Nix settings and shared package options.
            nixSharedSettings
            sharedPackageOptions
            qbittorrentOptions
          ]
          ++ modules;
        };
    };
  };
}
