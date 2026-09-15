# CODEX: CLAUDE-MEM SETTINGS
# =========================
# Declare the Claude-mem settings file inside its mutable .config data root

{
  config,
  lib,
  paths,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ SHARED CONFIGURATION ------ #
  # Keep the shared .config root and its linked settings path centralized.

  homeDir = paths.user.darwinHome;
  claudeMem = paths.darwin.agents.claudeMem;
  modeSettings = config.ven.codex.claudeMem.modeCreator;
  claudeMemSettingsRelativePath = lib.removePrefix "${homeDir}/" claudeMem.settings;
  modesRelativePath = lib.removePrefix "${homeDir}/" claudeMem.modes;

  # SETTINGS
  # =========================
  # Claude-mem merges this small declared file with its upstream defaults,
  # so newly introduced defaults continue to work after plugin updates.

  # PAUSE PRESETS
  # =========================
  # "CLAUDE_MEM_EXCLUDED_PROJECTS": "*"
  #   Pause Claude-mem for every project.
  # "CLAUDE_MEM_EXCLUDED_PROJECTS": ""
  #   Resume Claude-mem for every project.
  excludedProjects = "";

  claudeMemSettings = builtins.toJSON {
    CLAUDE_MEM_DATA_DIR = claudeMem.data;
    CLAUDE_MEM_TRANSCRIPTS_CONFIG_PATH = claudeMem.transcriptWatch;
    CLAUDE_MEM_WELCOME_HINT_ENABLED = "false";
    CLAUDE_MEM_EXCLUDED_PROJECTS = excludedProjects;
    CLAUDE_MEM_MODE = modeSettings.modeId;
    CLAUDE_MEM_TELEGRAM_TRIGGER_TYPES = lib.concatStringsSep "," modeSettings.telegram.types;
    CLAUDE_MEM_TELEGRAM_TRIGGER_CONCEPTS = lib.concatStringsSep "," modeSettings.telegram.concepts;
  };
in
{
  # MODE SETTINGS
  # =========================
  # Claude-mem settings and optional custom mode JSON form one feature:
  # the selected mode is rendered into settings.json, while local mode
  # definitions are linked only when the user declares one.

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

  # SETTINGS LINK
  # =========================
  # Link the immutable config while the database, logs, worker, and
  # transcript state remain mutable outside the Nix store.

  config.home-manager.users.${paths.user.name}.home.file =
    {
      "${claudeMemSettingsRelativePath}" = {
        force = true;
        text = claudeMemSettings;
      };
    }
    // lib.mapAttrs' (
      modeId: modeJson:
      lib.nameValuePair "${modesRelativePath}/${modeId}.json" {
        force = true;
        text = modeJson;
      }
    ) modeSettings.modes;
}
