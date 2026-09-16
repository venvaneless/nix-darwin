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
  # ------ CONVERSATION STORAGE ------ #
  # ------------------------------------------------------------
  # Codex records threads.rollout_path in each profile's state database and
  # derives a thread's archive destination from that path relative to
  # $CODEX_HOME. When it cannot find a thread where the database says it is,
  # it falls back to scanning and writes back the path it found -- the
  # symlink-resolved one.
  #
  # So a sessions/ directory that is a symlink out of the profile resolves to
  # a path outside $CODEX_HOME, the archive destination becomes unreachable,
  # and the app reports "Failed to archive chat". Rewriting the rows alone
  # does not hold: the next fallback scan restores the resolved spelling,
  # which is why the layout is fixed here and the rows are left to the app.
  #
  # The stable arrangement is for one profile to own the real directories, so
  # that resolving a path returns the string it started as. Everything else
  # links into it.
  #
  # ** Archiving is therefore structurally correct for the owner profile
  # ** only. A second profile sharing one conversation tree necessarily
  # ** resolves outside its own $CODEX_HOME. That is a Codex constraint.

  storageOwner = codex.chatgpt;

  storageLinked = [ codex.shared ];

  # Both directories are managed together because archiving moves a thread
  # between them, so they have to resolve consistently.
  storageKinds = [ "sessions" "archived_sessions" ];

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
          CODEX_API_KEY="$key" exec /run/current-system/sw/bin/codex "$@"
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


  # CODEX: CONVERSATION STORAGE
  # =================================================================
  # Runs on every activation and is idempotent: once the layout is correct
  # every branch is a no-op. Conversations are moved, never overwritten, and
  # nothing is touched at all while ChatGPT is running.

  system.activationScripts.extraActivation.text = lib.mkBefore ''
    # ---- Fast path
    # Every check below is a stat. pgrep, which costs more than all of
    # them together, only runs when something actually needs changing.
    codex_storage_ok=1

    ${lib.concatMapStringsSep "\n" (kind: ''
      if [ ! -d ${lib.escapeShellArg "${storageOwner}/${kind}"} ] \
        || [ -L ${lib.escapeShellArg "${storageOwner}/${kind}"} ]; then
        codex_storage_ok=0
      fi

      ${lib.concatMapStringsSep "\n" (root: ''
        if [ "$(readlink ${lib.escapeShellArg "${root}/${kind}"} 2>/dev/null)" \
          != ${lib.escapeShellArg "${storageOwner}/${kind}"} ]; then
          codex_storage_ok=0
        fi
      '') storageLinked}
    '') storageKinds}

    if [ "$codex_storage_ok" = 1 ]; then
      : # Layout is correct; nothing to do.
    elif /usr/bin/pgrep -qf ${lib.escapeShellArg chatgptProcess}; then
      echo "[nix-darwin][codex] ChatGPT is running; conversation storage left untouched." >&2
      echo "[nix-darwin][codex] Quit it and rebuild to finish the layout." >&2
    else
      echo "[nix-darwin][codex] Converging Codex conversation storage..."

      codex_owner_root=${lib.escapeShellArg storageOwner}

      for codex_kind in ${lib.escapeShellArgs storageKinds}; do
        codex_owner_dir="$codex_owner_root/$codex_kind"

        # ---- The owner profile holds the real directory.
        if [ -L "$codex_owner_dir" ]; then
          codex_link_target="$(readlink "$codex_owner_dir")"
          rm "$codex_owner_dir"

          if [ -d "$codex_link_target" ]; then
            mv "$codex_link_target" "$codex_owner_dir"
            echo "[nix-darwin][codex] Took ownership of $codex_kind from $codex_link_target"
          else
            mkdir -p "$codex_owner_dir"
          fi
        elif [ ! -e "$codex_owner_dir" ]; then
          mkdir -p "$codex_owner_dir"
        fi

        # ---- Every other location links at it.
        for codex_linked_root in ${lib.escapeShellArgs storageLinked}; do
          codex_linked_dir="$codex_linked_root/$codex_kind"

          if [ -L "$codex_linked_dir" ]; then
            if [ "$(readlink "$codex_linked_dir")" != "$codex_owner_dir" ]; then
              rm "$codex_linked_dir"
              ln -s "$codex_owner_dir" "$codex_linked_dir"
            fi

            continue
          fi

          if [ ! -e "$codex_linked_dir" ]; then
            mkdir -p "$codex_linked_root"
            ln -s "$codex_owner_dir" "$codex_linked_dir"
            continue
          fi

          # A real directory here still holds conversations. They are moved
          # one by one and a name that already exists at the destination is
          # left alone, so the directory survives instead of being replaced.
          codex_conflicts=0

          while IFS= read -r -d "" codex_file; do
            codex_relative="''${codex_file#"$codex_linked_dir"/}"
            codex_destination="$codex_owner_dir/$codex_relative"

            if [ -e "$codex_destination" ]; then
              codex_conflicts=$((codex_conflicts + 1))
              continue
            fi

            mkdir -p "$(dirname "$codex_destination")"
            mv "$codex_file" "$codex_destination"
          done < <(find "$codex_linked_dir" -type f ! -name '.DS_Store' -print0)

          find "$codex_linked_dir" -name '.DS_Store' -type f -delete

          if [ "$codex_conflicts" -ne 0 ]; then
            echo "[nix-darwin][codex] $codex_conflicts conflict(s); left $codex_linked_dir in place" >&2
            continue
          fi

          rm -r "$codex_linked_dir"
          ln -s "$codex_owner_dir" "$codex_linked_dir"
          echo "[nix-darwin][codex] Migrated $codex_linked_dir into the owner profile"
        done
      done
    fi
  '';


  # CODEX: ACTIVATION
  # =================================================================

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ven_uid="$(/usr/bin/id -u ${userName})"

    # ------ GUI SESSION ENVIRONMENT ------ #
    # Applies now; the codex-environment agent reapplies it at login.
    /bin/launchctl asuser "$ven_uid" /bin/sh -c ${lib.escapeShellArg setGuiEnvironment}

    # ------ APP DATA LINK ------ #
    # ChatGPT.app's default Electron data dir points into the Codex home.
    codex_app_data=${lib.escapeShellArg codex.appUserData}
    codex_app_target=${lib.escapeShellArg codex.electronUserData}

    if [ "$(readlink "$codex_app_data" 2>/dev/null)" = "$codex_app_target" ]; then
      : # Link is current.
    elif /usr/bin/pgrep -qf ${lib.escapeShellArg chatgptProcess}; then
      echo "[nix-darwin][codex] ChatGPT is running; app data link left untouched." >&2
    else
      if [ -e "$codex_app_data" ] || [ -L "$codex_app_data" ]; then
        codex_app_backup="$codex_app_data.before-nix-$(/bin/date +%Y%m%d-%H%M%S)"
        mv "$codex_app_data" "$codex_app_backup"
        echo "[nix-darwin][codex] Moved old app data to $codex_app_backup"
      fi

      /usr/bin/sudo -u ${userName} /bin/mkdir -p "$codex_app_target"
      /usr/bin/sudo -u ${userName} /bin/ln -s "$codex_app_target" "$codex_app_data"
      echo "[nix-darwin][codex] Linked $codex_app_data -> $codex_app_target"
    fi
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
