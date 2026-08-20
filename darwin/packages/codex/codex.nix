# darwin/packages/codex/codex.nix
#
# CODEX
# =====================================================================
# Installs the patched codex-profile package and declaratively manages
# the configuration for the GPT and API profiles.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  helpers = import ../../../options { inherit lib options pkgs; };

  inherit (helpers) paths;

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
  # does not hold: the next fallback scan restores the resolved spelling.
  #
  # The stable arrangement is for one profile to own the real directories, so
  # that resolving a path returns the string it started as. Everything else
  # links into it.
  #
  # ** Archiving is therefore structurally correct for the owner profile
  # ** only. A second profile sharing one conversation tree necessarily
  # ** resolves outside its own $CODEX_HOME. That is a Codex constraint.

  storageOwner = codex.chatgpt;

  storageLinked = [ codex.shared codex.api ];

  # Both directories are managed together because archiving moves a thread
  # between them, so they have to resolve consistently.
  storageKinds = [ "sessions" "archived_sessions" ];

  storageDatabases = map (root: "${root}/sqlite/state_5.sqlite") [
    codex.chatgpt
    codex.api
  ];

  # ------------------------------------------------------------
  # ------ DOCK LAUNCHER ------ #
  # ------------------------------------------------------------
  # Same derivation as the one installed through agents-pkgs.nix, so both
  # resolve to one store path.

  launcherPackage = pkgs.callPackage ./chatgpt-launcher.nix {
    inherit paths;
  };

  launcherBundle = paths.darwin.applications.bundles.codexChatgpt;

  launcherMarkerDirectory = "${paths.darwin.system.var}/lib/nix-darwin-codex";
  launcherMarker = "${launcherMarkerDirectory}/chatgpt-launcher.registered";

  lsregister =
    "/System/Library/Frameworks/CoreServices.framework"
    + "/Frameworks/LaunchServices.framework/Support/lsregister";
in
{

  # CODEX: ENVIRONMENT
  # =================================================================

  # Env variables
  environment.variables = {
    CODEX_HOME = codex.chatgpt;

    CODEX_PROFILE_HOME_ROOT = codexRoot;
    CODEX_PROFILE_CONFIG_HOME = codex.profileConfig;

    CHATGPT_APP = paths.darwin.applications.bundles.chatgpt;
    CODEX_CLI = "/run/current-system/sw/bin/codex";
  };


  # CODEX: CONVERSATION STORAGE
  # =================================================================
  # Runs on every activation and is idempotent: once the layout is correct
  # every branch is a no-op. Conversations are moved, never overwritten, and
  # nothing is touched at all while ChatGPT is running.

  system.activationScripts.extraActivation.text = lib.mkBefore ''
    echo "[nix-darwin][codex] Configuring Codex conversation storage..."

    codex_owner_root=${lib.escapeShellArg storageOwner}
    codex_shared_root=${lib.escapeShellArg codex.shared}

    if /usr/bin/pgrep -qf '/Applications/ChatGPT.app/Contents/MacOS/ChatGPT'; then
      echo "[nix-darwin][codex] ChatGPT is running; conversation storage left untouched." >&2
      echo "[nix-darwin][codex] Quit it and rebuild to finish the layout." >&2
    else
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

      # ---- Rows recorded under the old resolved path.
      # With the owner profile holding the real directories this rewrite is
      # durable: resolving a path now returns the same spelling.
      for codex_database in ${lib.escapeShellArgs storageDatabases}; do
        [ -f "$codex_database" ] || continue

        codex_stale="$(
          ${pkgs.sqlite}/bin/sqlite3 "file:$codex_database?mode=ro" \
            "SELECT COUNT(*) FROM threads WHERE rollout_path LIKE '$codex_shared_root/%';"
        )"

        if [ "$codex_stale" = "0" ]; then
          continue
        fi

        mkdir -p "$(dirname "$codex_database")/backups"

        ${pkgs.sqlite}/bin/sqlite3 "$codex_database" \
          ".backup '$(dirname "$codex_database")/backups/state_5.sqlite.$(date +%Y%m%d-%H%M%S)'"

        ${pkgs.sqlite}/bin/sqlite3 "$codex_database" \
          "UPDATE threads
              SET rollout_path = replace(rollout_path, '$codex_shared_root/', '$codex_owner_root/')
            WHERE rollout_path LIKE '$codex_shared_root/%';"

        echo "[nix-darwin][codex] Rewrote $codex_stale stale rollout path(s) in $codex_database"
      done
    fi
  '';


  # CODEX: ACTIVATION
  # =================================================================
  # Two things that only make sense once the store paths for this
  # generation exist, so they share one postActivation block.

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ven_uid="$(/usr/bin/id -u ${userName})"


    # ------ GUI SESSION ENVIRONMENT ------ #
    # environment.variables only reaches /etc/zshenv and /etc/bashrc.
    # Apps launched from the Dock, Spotlight, or Finder never source
    # those, so they are seeded into ven's launchd domain here.

    /bin/launchctl asuser "$ven_uid" \
      /bin/launchctl setenv CODEX_HOME ${lib.escapeShellArg codex.chatgpt}

    /bin/launchctl asuser "$ven_uid" \
      /bin/launchctl setenv CODEX_PROFILE_HOME_ROOT ${lib.escapeShellArg codexRoot}


    # ------ LAUNCHER REGISTRATION ------ #
    # /Applications/Nix Apps is refreshed from the Nix store on every
    # activation, so the launcher bundle is replaced whenever its store
    # path changes -- which happens on every nixpkgs bump, not only when
    # the launcher itself is edited. LaunchServices keeps serving the
    # icon and metadata it recorded for the previous bundle, so the Dock
    # tile silently reverts to a stale icon until it is registered again.
    #
    # The store path that was last registered is recorded, so this only
    # does work when it actually changes.

    codex_launcher_store_path=${lib.escapeShellArg launcherPackage}
    codex_launcher_bundle=${lib.escapeShellArg launcherBundle}
    codex_launcher_marker=${lib.escapeShellArg launcherMarker}
    codex_launcher_recorded=""

    if [ -f "$codex_launcher_marker" ]; then
      codex_launcher_recorded="$(/bin/cat "$codex_launcher_marker")"
    fi

    if [ ! -e "$codex_launcher_bundle" ]; then
      echo "[nix-darwin][codex] Launcher bundle is missing: $codex_launcher_bundle" >&2
    elif [ "$codex_launcher_recorded" = "$codex_launcher_store_path" ]; then
      : # Registration is current.
    elif [ ! -x ${lib.escapeShellArg lsregister} ]; then
      echo "[nix-darwin][codex] lsregister is unavailable; skipping registration." >&2
    else
      echo "[nix-darwin][codex] Registering $codex_launcher_bundle with LaunchServices..."

      # LaunchServices reads the per-user database, so registration and
      # the Dock restart both run inside ven's launchd domain.
      /bin/launchctl asuser "$ven_uid" \
        /usr/bin/sudo -u ${userName} \
        ${lib.escapeShellArg lsregister} -f "$codex_launcher_bundle"

      # The Dock caches the tile image, so it has to be reloaded before
      # the refreshed icon is used.
      /bin/launchctl asuser "$ven_uid" \
        /usr/bin/sudo -u ${userName} \
        /usr/bin/killall Dock || true

      /bin/mkdir -p ${lib.escapeShellArg launcherMarkerDirectory}
      printf '%s' "$codex_launcher_store_path" > "$codex_launcher_marker"
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
