# options/nix-config.nix
#
# =====================================================================
# OPTIONS: SHARED NIX KNOBS
#
# Declares the custom ven.nix knob interface and translates its values
# into the corresponding built-in Nix and Nixpkgs options.
# =====================================================================
{ config, lib, platforms, ... }:

let
  cfg = config.ven.nix;

  # ------------------------------------------------------------
  # ------ NIX SETTING VALUE AND MERGE RULES ------ #
  # Accepts Nix setting values. Lists merge uniquely; conflicting scalar
  # values deliberately fail. Actual values belong in shared/default.nix
  # or the relevant machine default.nix.
  # ------------------------------------------------------------
  settingType = lib.mkOptionType {
    name = "nixSetting";
    description = "boolean, number, string, or list of strings";

    check = value:
      lib.isBool value
      || lib.isInt value
      || lib.isFloat value
      || lib.isString value
      || (lib.isList value && lib.all lib.isString value);

    merge = loc: defs: let
      values = map (def: def.value) defs;
      unique = lib.unique values;
    in
      if lib.all lib.isList values
      then lib.unique (lib.concatLists values)
      else if lib.length unique == 1
      then lib.head unique
      else
        throw ''
          ${lib.showOption loc} is given more than one value:
            ${lib.concatMapStringsSep "\n    " (value: lib.generators.toPretty {} value) unique}

          Two files disagree about one setting. Use one shared value or
          override it deliberately with lib.mkForce in the machine.
        '';
  };

  # A setting is absent until a shared or machine module assigns it. This
  # preserves Nix's own default instead of inventing one for every host.
  nullable = type: lib.types.nullOr type;

  unstableEnabledForCurrentPlatform =
    cfg.nixpkgs.unstable.enable
    && (
      (platforms.isDarwin && cfg.nixpkgs.unstable.installOn.darwin)
      || (platforms.isLinux && cfg.nixpkgs.unstable.installOn.linux)
    );
in {
  # ------------------------------------------------------------
  # ------ CUSTOM KNOB INTERFACE ------ #
  # ------------------------------------------------------------
  options.ven.nix = {
    settings = lib.mkOption {
      default = {};
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf settingType;

        options = {
          experimental-features = lib.mkOption {
            type = nullable (lib.types.listOf lib.types.str);
            default = null;
            description = "Experimental Nix features, including nix-command and flakes.";
          };

          build-users-group = lib.mkOption {
            type = nullable lib.types.str;
            default = null;
            description = "Nix build-users group used by nix-darwin or NixOS.";
          };

          use-xdg-base-directories = lib.mkOption {
            type = nullable lib.types.bool;
            default = null;
            description = "Use XDG base directories for Nix user profiles and channels.";
          };

          log-lines = lib.mkOption {
            type = nullable lib.types.int;
            default = null;
            description = "Number of lines Nix includes from failed build logs.";
          };

          max-jobs = lib.mkOption {
            type = nullable lib.types.int;
            default = null;
            description = "Maximum number of concurrent Nix build jobs.";
          };

          cores = lib.mkOption {
            type = nullable lib.types.int;
            default = null;
            description = "Maximum number of CPU cores available to one Nix build.";
          };

          fallback = lib.mkOption {
            type = nullable lib.types.bool;
            default = null;
            description = "Build locally when a binary substitute cannot be obtained.";
          };

          trusted-users = lib.mkOption {
            type = nullable (lib.types.listOf lib.types.str);
            default = null;
            description = "Users permitted to pass trusted settings to the Nix daemon.";
          };

          keep-derivations = lib.mkOption {
            type = nullable lib.types.bool;
            default = null;
            description = "Keep derivation files after their outputs are built.";
          };

          keep-outputs = lib.mkOption {
            type = nullable lib.types.bool;
            default = null;
            description = "Keep build outputs reachable from their derivations.";
          };

          optimise.automatic = lib.mkOption {
            type = nullable lib.types.bool;
            default = null;
            description = "Hard-link duplicate store files automatically.";
          };
        };
      };
      description = ''
        Nix settings under their real nix.conf names. Other valid nix.conf
        settings remain available through the freeform interface.
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
  # Values assigned by shared/default.nix and host modules become
  # nix.settings, nix.optimise.automatic, and nixpkgs.config only here.
  # ------------------------------------------------------------
  config = {
    # The shared system module assigns the user-facing shared Nix values.
    # This logic module only derives the platform-specific read-only result.
    ven.nix.nixpkgs.unstable.enabledForCurrentPlatform = unstableEnabledForCurrentPlatform;

    nixpkgs.config = cfg.nixpkgs.config;

    nix.optimise.automatic = lib.mkIf (cfg.settings.optimise.automatic != null)
      cfg.settings.optimise.automatic;

    nix.settings = lib.filterAttrs (_: value: value != null) (
      removeAttrs cfg.settings [
        "optimise"
        "_module"
      ]
    );
  };
}
