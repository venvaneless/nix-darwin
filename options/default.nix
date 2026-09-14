# options/default.nix
#
# =====================================================================
# OPTIONS: SHARED NIX KNOBS
#
# Declares the custom ven.nix knob interface used by shared/default.nix
# and machine modules. When directly imported by host construction, it
# also exposes shared values and Home Manager option-module paths.
# =====================================================================

{
  config ? null,
  inputs ? null,
  lib ? null,
  nixSharedSettings ? null,
  options ? null,
  pkgs ? null,
  platforms ? null,
  ...
}@args:

# Branch on whether a `config` argument was supplied, never on its value.
# The module system must read this file's top-level attributes before its
# fixpoint exists, so forcing `config` here (e.g. `config == null`) causes
# infinite recursion. `args ? config` inspects attribute names only.
if !(args ? config) then
  let
    # ------------------------------------------------------------
    # ------ SHARED HOST VALUES ------ #
    # Host construction reads these before a system or Home Manager
    # module fixpoint exists. This branch never declares options.
    # ------------------------------------------------------------
    sharedSettings = import ../shared/default.nix;
    nixpkgsSettings = sharedSettings.ven.nix.nixpkgs;
    nixpkgsConfig = nixpkgsSettings.config;

    unstableEnabled =
      nixpkgsSettings.unstable.enable
      && (
        (pkgs.stdenv.hostPlatform.isDarwin && nixpkgsSettings.unstable.installOn.darwin)
        || (pkgs.stdenv.hostPlatform.isLinux && nixpkgsSettings.unstable.installOn.linux)
      );

    unstablePkgs =
      if unstableEnabled then
        import inputs.nixpkgs-unstable {
          system = pkgs.stdenv.hostPlatform.system;
          config = nixpkgsConfig;
        }
      else
        throw "ven.nix.nixpkgs.unstable is disabled for this platform.";

    paths = import ./paths.nix { };
  in
  {
    inherit nixpkgsConfig unstablePkgs paths;
    nixSharedSettings = sharedSettings;

    # Home Manager option-module paths supplied through extraSpecialArgs.
    serviceOptions = ./services/default.nix;
    containerBackupOptions = ./backups/container-backup-helper.nix;
    terminalOptions = ./terminal-aliases.nix;
    featureOptions = ./terminal-features.nix;
    cliOptions = ./cli/default.nix;
    obsidianOptions = ./obsidian/default.nix;

    # The consolidated system option module supplied to host constructors.
    nixOptions = ./default.nix;
  }
else
  let
    cfg = config.ven.nix;
    sharedNix = nixSharedSettings.ven.nix;

    # ------------------------------------------------------------
    # ------ DEFAULT MARKER ------ #
    # A consumer binds `default = config.ven.nix.default;` and can use
    # `cores = default;` to select the repository default below.
    # ------------------------------------------------------------
    marker = "@default@";

    # ------------------------------------------------------------
    # ------ REPOSITORY DEFAULTS ------ #
    # Applies only when a consumer explicitly sets a setting to `default`.
    # A setting not assigned anywhere remains Nix's own default.
    # ------------------------------------------------------------
    defaults = {
      max-jobs = 4;
      cores = 2;
      fallback = true;
      warn-dirty = false;
      log-lines = 50;
      keep-derivations = true;
      keep-outputs = true;
      use-xdg-base-directories = true;

      # This is a nix-darwin/NixOS option, not a nix.conf setting.
      "optimise.automatic" = true;
    };

    # ------------------------------------------------------------
    # ------ NIX SETTING VALUE AND MERGE RULES ------ #
    # Accepts Nix setting values plus the custom default marker. Lists
    # merge uniquely; conflicting scalar values deliberately fail.
    # ------------------------------------------------------------
    settingType = lib.mkOptionType {
      name = "nixSetting";
      description = "boolean, number, string, list of strings, or default";

      check =
        value:
        value == marker
        || lib.isBool value
        || lib.isInt value
        || lib.isFloat value
        || lib.isString value
        || (lib.isList value && lib.all lib.isString value);

      merge =
        loc: defs:
        let
          stated = lib.filter (def: def.value != marker) defs;
          values = map (def: def.value) stated;
          unique = lib.unique values;
        in
        if stated == [ ] then
          marker
        else if lib.all lib.isList values then
          lib.unique (lib.concatLists values)
        else if lib.length unique == 1 then
          lib.head unique
        else
          throw ''
            ${lib.showOption loc} is given more than one value:
              ${lib.concatMapStringsSep "\n    " (value: lib.generators.toPretty { } value) unique}

            Two files disagree about one setting. Leave the shared one as
            default, or override it with lib.mkForce in the machine.
          '';
    };

    # ------------------------------------------------------------
    # ------ DEFAULT RESOLUTION ------ #
    # Converts the custom marker to its declared value immediately before
    # writing to the real Nix option.
    # ------------------------------------------------------------
    resolve =
      name: value:
      if value != marker then
        value
      else if defaults ? ${name} then
        defaults.${name}
      else
        throw ''
          ven.nix.settings.${name} is set to default, but options/default.nix
          declares no default for it. Write a real machine-specific value.
        '';

    unstableEnabledForCurrentPlatform =
      cfg.nixpkgs.unstable.enable
      && (
        (platforms.isDarwin && cfg.nixpkgs.unstable.installOn.darwin)
        || (platforms.isLinux && cfg.nixpkgs.unstable.installOn.linux)
      );
  in
  {
    # ------------------------------------------------------------
    # ------ CUSTOM KNOB INTERFACE ------ #
    # ------------------------------------------------------------
    options.ven.nix = {
      default = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = marker;
        description = ''
          Marker for selecting the default declared in options/default.nix.
          Bind this to `default` before writing ven.nix.settings values.
        '';
      };

      settings = lib.mkOption {
        default = { };
        type = lib.types.submodule {
          freeformType = lib.types.attrsOf settingType;

          options.optimise.automatic = lib.mkOption {
            type = settingType;
            default = marker;
            description = "Hard-link duplicate store files automatically.";
          };
        };
        example = lib.literalExpression ''
          {
            cores = default;
            max-jobs = 8;
            optimise.automatic = default;
            trusted-users = [ "root" "ven" ];
            build-users-group = "nixbld";
          }
        '';
        description = ''
          Nix settings under their real nix.conf names. Values may be real
          values or the custom `default` marker. List values merge uniquely.
        '';
      };

      nixpkgs = {
        config = lib.mkOption {
          type = lib.types.attrs;
          description = "Nixpkgs policy shared by the stable and unstable package sets.";
        };

        unstable = {
          enable = lib.mkEnableOption "the unstable Nixpkgs package set";

          installOn = lib.mkOption {
            type = lib.types.submodule {
              options = {
                darwin = lib.mkOption {
                  type = lib.types.bool;
                  description = "Make the unstable package set available on Darwin.";
                };
                linux = lib.mkOption {
                  type = lib.types.bool;
                  description = "Make the unstable package set available on Linux.";
                };
              };
            };
            description = "Platforms where enabled consumers may use unstablePkgs.";
          };

          enabledForCurrentPlatform = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
            description = "Whether unstablePkgs is available on the current platform.";
          };
        };
      };
    };

    # ------------------------------------------------------------
    # ------ TRANSLATION TO BUILT-IN NIX OPTIONS ------ #
    # The values assigned by shared/default.nix and host modules become
    # nix.settings, nix.optimise.automatic, and nixpkgs.config only here.
    # ------------------------------------------------------------
    config = {
      # Shared/default.nix assigns values to the custom knobs. The module
      # logic below translates them into the corresponding built-in options.
      ven.nix.settings = sharedNix.settings;
      ven.nix.nixpkgs = lib.recursiveUpdate sharedNix.nixpkgs {
        unstable.enabledForCurrentPlatform = unstableEnabledForCurrentPlatform;
      };

      nixpkgs.config = cfg.nixpkgs.config;

      nix.optimise.automatic = resolve "optimise.automatic" cfg.settings.optimise.automatic;

      nix.settings = lib.mapAttrs resolve (
        removeAttrs cfg.settings [
          "optimise"
          "_module"
        ]
      );
    };
  }
