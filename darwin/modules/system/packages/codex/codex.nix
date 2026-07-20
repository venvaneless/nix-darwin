# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/codex/codex.nix
#
# CODEX
# =====================================================================
# Installs the patched codex-profile package and declaratively manages
# the configuration for the GPT and API profiles.
# =====================================================================

{...}:

let
  userName = "ven";
  homeDir = "/Users/${userName}";

  codexRoot = "${homeDir}/.config/codex";
in
{

  # CODEX: ENVIRONMENT
  # =================================================================

  environment.variables = {
    CODEX_PROFILE_HOME_ROOT = codexRoot;
    CODEX_PROFILE_CONFIG_HOME = "${homeDir}/.config/codex-profile";

    CHATGPT_APP = "/Applications/ChatGPT Classic.app";
  };

  # CODEX: HOME MANAGER CONFIGURATION
  # =================================================================
  #
  # Uncomment these entries after creating:
  #
  #   ./codex/gpt-config.toml
  #   ./codex/api-config.toml
  #
  # home-manager.users.${userName} = {
  #   home.file = {
  #     ".config/codex/gpt/config.toml".source =
  #       ./codex/gpt-config.toml;
  #
  #     ".config/codex/api/config.toml".source =
  #       ./codex/api-config.toml;
  #   };
  # };
}