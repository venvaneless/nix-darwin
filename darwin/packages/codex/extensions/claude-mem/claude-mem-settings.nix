# CODEX: CLAUDE-MEM SETTINGS
# =========================
# Declare the Claude-mem settings file without taking ownership of memory data

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
  # Keep the settings path and existing mutable data path centralized.

  helpers = import ../../../../../options { inherit lib options pkgs; };
  inherit (helpers) paths;

  homeDir = paths.user.darwinHome;
  claudeMem = paths.darwin.agents.claudeMem;
  modeCreator = config.ven.codex.claudeMem.modeCreator;
  claudeMemSettingsRelativePath = lib.removePrefix "${homeDir}/" claudeMem.settings;

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
    CLAUDE_MEM_EXCLUDED_PROJECTS = excludedProjects;
    CLAUDE_MEM_MODE = modeCreator.modeId;
    CLAUDE_MEM_TELEGRAM_TRIGGER_TYPES = lib.concatStringsSep "," modeCreator.telegram.types;
    CLAUDE_MEM_TELEGRAM_TRIGGER_CONCEPTS = lib.concatStringsSep "," modeCreator.telegram.concepts;
  };
in
{
  # SETTINGS LINK
  # =========================
  # Link the immutable config while the database, logs, worker, and
  # transcript state remain mutable outside the Nix store.

  home-manager.users.${paths.user.name}.home.file."${claudeMemSettingsRelativePath}" = {
    force = true;
    text = claudeMemSettings;
  };
}
