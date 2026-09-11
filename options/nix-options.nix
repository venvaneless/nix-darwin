# options/nix-options.nix
#
# =====================================================================
# OPTIONS: NIX ITSELF
#
# The logic behind ven.nix.settings, and the defaults it resolves. This
# is the only file that holds a value nobody wrote on purpose, and the
# only one that has to be edited to change what default means.
#
# ---- WHAT IT GIVES YOU ----
#
# ven.nix.settings takes the real nix.conf names, so a block reads like
# the nix.settings it becomes. Every setting is either a value or the
# word default:
#
#   ven.nix.settings = {
#     cores = default;                        # the 2 declared below
#     max-jobs = 8;                           # here only
#     trusted-users = [ "root" "ven" ];
#     build-users-group = "nixbld";
#   };
#
# The same block is valid in shared/nix-options.nix for every machine and
# in any machine's own default.nix.
#
# ** It is ven.nix.settings and not nix.settings for one reason: nothing
# ** could resolve a marker written directly into nix.settings, because no
# ** module can read and rewrite the same option. It would reach nix.conf
# ** as the literal text. The key names are the real ones either way.
#
# ---- HOW TWO FILES COMBINE ----
#
# ** default drops out. A setting left as default in one file and given a
# ** value in another takes that value, whichever file it came from.
#
# ** Lists add up, without duplicates. trusted-users in shared and again
# ** in a machine gives both sets of users, which is how a machine adds
# ** one.
#
# ** Two different real values for one setting is an error, on purpose:
# ** two files disagree. Leave the shared one as default, or override it
# ** with lib.mkForce.
#
# ** A setting nobody writes never reaches nix.conf, so Nix keeps its own
# ** behaviour rather than this repository inventing a value.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.nix;

  # ------------------------------------------------------------
  # ------ THE DEFAULT MARKER ------ #
  #
  # A file puts it in scope with:
  #
  #   let default = config.ven.nix.default; in
  # ------------------------------------------------------------

  marker = "@default@";

  # ------------------------------------------------------------
  # ------ THE DEFAULTS ------ #
  #
  # What default means, under the real nix.conf name. Changing a value
  # here changes every machine that left that setting as default.
  #
  # ** Only settings every machine can share a value for are listed. A
  # ** group name or a user list belongs to the machine that has it, so
  # ** writing default for one of those is an error rather than a guess.
  #
  # ** These are the values the MacBook already used.
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

    # Not a nix.conf setting but a nix-darwin and NixOS option. Declared
    # with the settings so one block covers everything about Nix, and
    # routed to nix.optimise below.
    "optimise.automatic" = true;
  };

  # ------------------------------------------------------------
  # ------ ONE SETTING'S VALUE ------ #
  #
  # Accepts what nix.conf accepts, plus the marker. The merge is what
  # lets several files write the same setting.
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
        # Whoever wrote default is not expressing an opinion.
        stated = lib.filter (def: def.value != marker) defs;

        values = map (def: def.value) stated;

        unique = lib.unique values;
      in
      if stated == [ ] then
        marker

      # Lists add up. Duplicates are dropped, so root written in two files
      # is one entry in nix.conf.
      else if lib.all lib.isList values then
        lib.unique (lib.concatLists values)

      # One opinion, or the same opinion twice.
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
  # ------ RESOLUTION ------ #
  # ------------------------------------------------------------

  resolve =
    name: value:
    if value != marker then
      value
    else if defaults ? ${name} then
      defaults.${name}
    else
      throw ''
        ven.nix.settings.${name} is set to default, but
        options/nix-options.nix declares no default for it.

        Settings such as build-users-group or trusted-users belong to the
        machine that has them, so write the value instead.
      '';
in

{
  # ------------------------------------------------------------
  # ------ OPTIONS ------ #
  # ------------------------------------------------------------

  options.ven.nix = {
    default = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = marker;
      description = ''
        Bind this to write cores = default. Read-only: it means "the value
        declared in options/nix-options.nix", not a value of its own.
      '';
    };

    settings = lib.mkOption {
      default = { };

      # Freeform, so every nix.conf setting can be written under its own
      # name without this file listing them. optimise.automatic is
      # declared explicitly because it is not a nix.conf setting and has to
      # be routed elsewhere.
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf settingType;

        options.optimise.automatic = lib.mkOption {
          type = settingType;
          default = marker;
          description = ''
            Hard-link duplicate files in the store automatically. Becomes
            nix.optimise.automatic rather than a nix.conf setting.
          '';
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
        Nix settings, under their real nix.conf names. Written in
        shared/nix-options.nix for every machine and in a machine's own
        default.nix for itself. Each value is either a real value or
        default.

        Adding to a list works two ways: write the setting again in
        another file and the lists merge, or use the extra- name Nix
        provides for the same purpose, which passes through untouched:

          extra-trusted-users = [ "builder" ];
      '';
    };
  };

  # ------------------------------------------------------------
  # ------ TRANSLATION INTO NIX ------ #
  #
  # The only place these values become real settings.
  # ------------------------------------------------------------

  config = {
    # ---- Deduplicate store paths
    # Declared with the settings for one place to look, applied here to
    # the option that owns it.
    nix.optimise.automatic = resolve "optimise.automatic" cfg.settings.optimise.automatic;

    # Everything else is a real nix.conf setting under its own name.
    nix.settings = lib.mapAttrs resolve (
      removeAttrs cfg.settings [
        "optimise"
        "_module"
      ]
    );
  };
}
