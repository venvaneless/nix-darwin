# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/codex/codex.nix
#
# CODEX
# =====================================================================
# Installs the patched codex-profile package and declaratively manages
# the configuration for the GPT and API profiles.
# =====================================================================

{ lib, ... }:

let
  # Set the user name and home directory
  userName = "ven";
  homeDir = "/Users/${userName}";

  # Set the root directory for codex configuration
  codexRoot = "${homeDir}/.config/codex";
in
{

  # CODEX: GUI SESSION ENVIRONMENT
  # =================================================================
  # Make the ChatGPT profile the default for apps launched normally
  # from the Dock, Spotlight, or Finder. Also expose the shared Codex
  # profile root to the macOS GUI session.
  # Env variables
  environment.variables = {
    # CODEX_HOME = "${codexRoot}/chatgpt";
    
    CODEX_PROFILE_HOME_ROOT = codexRoot;
    CODEX_PROFILE_CONFIG_HOME = "${homeDir}/.config/codex-profile";

    CHATGPT_APP = "/Applications/ChatGPT.app";
    CODEX_CLI = "/run/current-system/sw/bin/codex";
  };


  # CODEX: GUI SESSION ENVIRONMENT
    # =================================================================
    # environment.variables only reaches /etc/zshenv and /etc/bashrc.
    # Apps launched from the Dock, Spotlight, or Finder never source
    # those, so they are seeded into ven's launchd domain here.
  
  system.activationScripts.postActivation.text = lib.mkAfter ''
    ven_uid="$(/usr/bin/id -u ${userName})"

    /bin/launchctl asuser "$ven_uid" \
      /bin/launchctl unsetenv CODEX_HOME

    /bin/launchctl asuser "$ven_uid" \
      /bin/launchctl setenv CODEX_PROFILE_HOME_ROOT "${codexRoot}"
  '';

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