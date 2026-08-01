# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/codex/codex.nix
#
# CODEX
# =====================================================================
# Installs the patched codex-profile package and declaratively manages
# the configuration for the GPT and API profiles.
# =====================================================================

{...}:

let
  # Set the user name and home directory
  userName = "ven";
  homeDir = "/Users/${userName}";

  # Set the root directory for codex configuration
  codexRoot = "${homeDir}/.config/codex";
in
{

  # CODEX: ENVIRONMENT
  # =================================================================

  # Env variables
  environment.variables = {
    CODEX_PROFILE_HOME_ROOT = codexRoot;
    CODEX_PROFILE_CONFIG_HOME = "${homeDir}/.config/codex-profile";

    CHATGPT_APP = "/Applications/ChatGPT.app";
    CODEX_CLI = "/run/current-system/sw/bin/codex";
  };

  # CODEX: HOME MANAGER CONFIGURATION
  # =================================================================
  #
  # Uncomment these entries after creating:
  #
  #   ./chatgpt-config.toml
  #   ./api-config.toml
  #
  # home-manager.users.${userName} = {
  #   home.file = {
  #     ...
  #   };
  # };
}