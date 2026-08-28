# options/services/unison.nix
#
# =====================================================================
# OPTIONS: UNISON
#
# Defines the common configurable Unison behavior.
#
# Built-in defaults may be overridden globally in:
#   options/services/default.nix
#
# Individual machines may then override those global defaults again.
# =====================================================================

{ lib, ... }:

{
  options.ven.services.unison = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "Unison-backed synchronization";

        auto = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically accept non-conflicting changes.";
        };

        batch = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run Unison without interactive prompts.";
        };

        fastCheck = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use Unison fast change detection.";
        };

        confirmBigDeletes = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Require confirmation for unusually large deletion propagation.";
        };
      };
    };

    default = { };
    description = "Shared Unison settings used by synchronization services.";
  };
}
