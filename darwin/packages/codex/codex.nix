# darwin/packages/codex/codex.nix
#
# CODEX
# =====================================================================
# Installs the patched codex-profile package and declaratively manages
# the configuration for the GPT and API profiles.
# =====================================================================

{ lib, paths, pkgs, ... }:

let
  userName = paths.user.name;

  codex = paths.darwin.agents.codex;

  # Set the root directory for codex configuration
  codexRoot = codex.root;

  # ------------------------------------------------------------
  # ------ SHARED ENVIRONMENT ------ #
  # ------------------------------------------------------------

  chatgptApp = paths.darwin.applications.bundles.chatgpt;
  chatgptProcess = "${chatgptApp}/Contents/MacOS/ChatGPT";

  codexEnvironment = {
    CODEX_HOME = codex.chatgpt;
    CODEX_SQLITE_HOME = codex.sqlite;
    CODEX_PROFILE_HOME_ROOT = codexRoot;
  };

  setGuiEnvironment = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: value: "/bin/launchctl setenv ${name} ${lib.escapeShellArg value}")
    codexEnvironment);

  # ------------------------------------------------------------
  # ------ API LAUNCHER ------ #
  # ------------------------------------------------------------
  # Same home and database as the subscription login; only the key differs.

  codexApi = pkgs.writeShellApplication {
    name = "codex-api";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      mode="''${1:-app}"
      [ "$#" -eq 0 ] || shift

      key="$(jq -r '.OPENAI_API_KEY // empty' ${lib.escapeShellArg codex.apiKeyFile})"
      if [ -z "$key" ]; then
        echo "No OPENAI_API_KEY in ${codex.apiKeyFile}" >&2
        exit 1
      fi

      export CODEX_HOME=${lib.escapeShellArg codex.chatgpt}
      export CODEX_SQLITE_HOME=${lib.escapeShellArg codex.sqlite}

      case "$mode" in
        app)
          if /usr/bin/pgrep -qf ${lib.escapeShellArg chatgptProcess}; then
            echo "Codex is already running. Quit it first." >&2
            exit 1
          fi

          exec /usr/bin/open \
            --env "CODEX_HOME=$CODEX_HOME" \
            --env "CODEX_SQLITE_HOME=$CODEX_SQLITE_HOME" \
            --env "CODEX_API_KEY=$key" \
            -a ${lib.escapeShellArg chatgptApp}
          ;;
        cli)
          # -p layers $CODEX_HOME/api.config.toml over config.toml.
          CODEX_API_KEY="$key" exec /run/current-system/sw/bin/codex -p api "$@"
          ;;
        *)
          echo "Usage: codex-api [app|cli] [codex args...]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{

  # CODEX: ENVIRONMENT
  # =================================================================

  # Env variables
  environment.variables = codexEnvironment // {
    CODEX_PROFILE_CONFIG_HOME = codex.profileConfig;

    CHATGPT_APP = chatgptApp;
    CODEX_CLI = "/run/current-system/sw/bin/codex";
  };

  environment.systemPackages = [ codexApi ];

  # GUI environment at login; launchctl setenv does not survive a reboot.
  launchd.user.agents.codex-environment.serviceConfig = {
    ProgramArguments = [ "/bin/sh" "-c" setGuiEnvironment ];
    RunAtLoad = true;
  };


  # CODEX: ACTIVATION
  # =================================================================

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ven_uid="$(/usr/bin/id -u ${userName})"

    # ------ GUI SESSION ENVIRONMENT ------ #
    # Applies now; the codex-environment agent reapplies it at login.
    /bin/launchctl asuser "$ven_uid" /bin/sh -c ${lib.escapeShellArg setGuiEnvironment}
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
