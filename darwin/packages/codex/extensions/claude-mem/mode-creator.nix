# CODEX: CLAUDE-MEM MODE CREATOR
# =========================
# Declare custom memory modes and non-secret notification choices

{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ SHARED CONFIGURATION ------ #
  # Keep mode files and their selected mode aligned with Claude-mem paths.

  helpers = import ../../../../../options { inherit lib options pkgs; };
  inherit (helpers) paths;

  cfg = config.ven.codex.claudeMem.modeCreator;
  homeDir = paths.user.darwinHome;
  modesRelativePath = lib.removePrefix "${homeDir}/" paths.darwin.agents.claudeMem.modes;
in
{
  # OPTIONS
  # =========================
  # A custom mode is declared as JSON by its mode ID and linked where the
  # worker expects it. Bundled modes such as code require no local JSON file.

  options.ven.codex.claudeMem.modeCreator = {
    modeId = lib.mkOption {
      type = lib.types.str;
      default = "code";
      description = "Claude-mem mode ID selected for future observations.";
    };

    modes = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Custom Claude-mem mode JSON keyed by mode ID.";
    };

    telegram = {
      types = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "security_alert"
          "sensitive"
        ];
        description = "Claude-mem observation types that trigger Telegram alerts.";
      };

      concepts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Claude-mem concepts that trigger Telegram alerts.";
      };
    };
  };

  # MODE FILES
  # =========================
  # Mode definitions are safe immutable configuration. Bot credentials remain
  # outside Nix because secrets must never enter the Nix store.

  config = lib.mkIf (cfg.modes != { }) {
    home-manager.users.${paths.user.name}.home.file = lib.mapAttrs' (
      modeId: modeJson:
      lib.nameValuePair "${modesRelativePath}/${modeId}.json" {
        force = true;
        text = modeJson;
      }
    ) cfg.modes;
  };
}
