# options/default.nix
#
# =====================================================================
# OPTIONS: SHARED NIX KNOBS
#
# Declares the custom ven.nix knob interface and translates its values
# into the corresponding built-in Nix and Nixpkgs options. When host
# construction imports this directory as a plain value, it also exports
# the shared context and option-module paths used by the module graph.
# =====================================================================
{
  config ? null,
  inputs ? null,
  lib ? null,
  nixSharedSettings ? null,
  pkgs ? null,
  platforms ? null,
  ...
}@args:

# Host construction happens before a module fixpoint exists, whereas the
# option module needs that fixpoint. Test for the argument name only: reading
# config here would recurse while the module system is assembling itself.
if !(args ? config) then
  let
    # ------------------------------------------------------------
    # ------ SHARED HOST VALUES ------ #
    # The host constructor imports this branch once and passes the returned
    # values through specialArgs or extraSpecialArgs. Option modules are
    # paths here, not imports: each composition layer imports them once.

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
      else throw "ven.nix.nixpkgs.unstable is disabled for this platform.";

    paths = import ./paths.nix { };
  in
  {
    inherit nixpkgsConfig paths unstablePkgs;
    nixSharedSettings = sharedSettings;

    # ---- Option module paths
    # These are supplied to host composition through the same context rather
    # than scattered direct imports from outside options/.
    serviceOptions = ./services/default.nix;
    containerBackupOptions = ./backups/container-backup-helper.nix;
    terminalOptions = ./terminal-aliases.nix;
    featureOptions = ./terminal-features.nix;
    cliOptions = ./cli/default.nix;
    envSettingsOptions = ./env-settings;
    espansoOptions = ./pkgs-configs/espanso;
    obsidianOptions = ./obsidian/default.nix;
    nixOptions = ./default.nix;
  }
else let
  cfg = config.ven.nix;

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

    check = value:
      value
      == marker
      || lib.isBool value
      || lib.isInt value
      || lib.isFloat value
      || lib.isString value
      || (lib.isList value && lib.all lib.isString value);

    merge = loc: defs: let
      stated = lib.filter (def: def.value != marker) defs;
      values = map (def: def.value) stated;
      unique = lib.unique values;
    in
      if stated == []
      then marker
      else if lib.all lib.isList values
      then lib.unique (lib.concatLists values)
      else if lib.length unique == 1
      then lib.head unique
      else
        throw ''
          ${lib.showOption loc} is given more than one value:
            ${lib.concatMapStringsSep "\n    " (value: lib.generators.toPretty {} value) unique}

          Two files disagree about one setting. Leave the shared one as
          default, or override it with lib.mkForce in the machine.
        '';
  };

  # A setting is absent until a shared or machine module assigns it. This
  # preserves Nix's own default instead of inventing one for every host.
  defaultable = type: lib.types.nullOr (lib.types.either type (lib.types.enum [marker]));

  # ------------------------------------------------------------
  # ------ DEFAULT RESOLUTION ------ #
  # Converts the custom marker to its declared value immediately before
  # writing to the real Nix option.
  # ------------------------------------------------------------
  resolve = name: value:
    if value != marker
    then value
    else if defaults ? ${name}
    then defaults.${name}
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
in {
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
      default = {};
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf settingType;

        options = {
          build-users-group = lib.mkOption {
            type = defaultable lib.types.str;
            default = null;
            description = "Nix build-users group used by nix-darwin or NixOS.";
          };

          use-xdg-base-directories = lib.mkOption {
            type = defaultable lib.types.bool;
            default = null;
            description = "Use XDG base directories for Nix user profiles and channels.";
          };

          log-lines = lib.mkOption {
            type = defaultable lib.types.int;
            default = null;
            description = "Number of lines Nix includes from failed build logs.";
          };

          max-jobs = lib.mkOption {
            type = defaultable lib.types.int;
            default = null;
            description = "Maximum number of concurrent Nix build jobs.";
          };

          cores = lib.mkOption {
            type = defaultable lib.types.int;
            default = null;
            description = "Maximum number of CPU cores available to one Nix build.";
          };

          fallback = lib.mkOption {
            type = defaultable lib.types.bool;
            default = null;
            description = "Build locally when a binary substitute cannot be obtained.";
          };

          trusted-users = lib.mkOption {
            type = defaultable (lib.types.listOf lib.types.str);
            default = null;
            description = "Users permitted to pass trusted settings to the Nix daemon.";
          };

          keep-derivations = lib.mkOption {
            type = defaultable lib.types.bool;
            default = null;
            description = "Keep derivation files after their outputs are built.";
          };

          keep-outputs = lib.mkOption {
            type = defaultable lib.types.bool;
            default = null;
            description = "Keep build outputs reachable from their derivations.";
          };

          optimise.automatic = lib.mkOption {
            type = defaultable lib.types.bool;
            default = null;
            description = "Hard-link duplicate store files automatically.";
          };
        };
      };
      description = ''
        Nix settings under their real nix.conf names. Each documented setting
        may be assigned a value or the custom `default` marker. Other valid
        nix.conf settings remain available through the freeform interface.
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
    # The plain host branch passes shared/default.nix through
    # nixSharedSettings. Keeping the values here lets the host import this
    # one option module instead of importing shared/default.nix separately.
    ven.nix.settings = nixSharedSettings.ven.nix.settings;

    ven.nix.nixpkgs = lib.recursiveUpdate nixSharedSettings.ven.nix.nixpkgs {
      unstable.enabledForCurrentPlatform = unstableEnabledForCurrentPlatform;
    };

    nixpkgs.config = cfg.nixpkgs.config;

    nix.optimise.automatic = lib.mkIf (cfg.settings.optimise.automatic != null) (
      resolve "optimise.automatic" cfg.settings.optimise.automatic
    );

    nix.settings = lib.mapAttrs resolve (
      lib.filterAttrs (_: value: value != null) (
        removeAttrs cfg.settings [
          "optimise"
          "_module"
        ]
      )
    );
  };
}
