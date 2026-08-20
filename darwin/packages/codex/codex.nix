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
  # ------ DOCK LAUNCHER ------ #
  # ------------------------------------------------------------
  # Same derivation as the one installed through agents-pkgs.nix, so
  # both resolve to one store path.

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
    # tile silently reverts to a stale icon until the bundle is
    # registered again.
    #
    # The store path that was last registered is recorded, so this only
    # does work when it actually changes.

    echo "[nix-darwin][codex] Checking the Codex ChatGPT launcher registration..."

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
      echo "[nix-darwin][codex] Launcher registration is current."
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

      echo "[nix-darwin][codex] Launcher registration refreshed."
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
