# CODEX: CLAUDE-MEM
# =========================
# Register and update the Claude-mem Codex plugin for both profiles

{
  inputs,
  lib,
  options,
  pkgs,
  unstablePkgs,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ SHARED CONFIGURATION ------ #
  # Keep the marketplace registration aligned with the shared profiles.

  helpers = import ../../../../../options { inherit lib options pkgs; };
  inherit (helpers) paths;

  userName = paths.user.name;
  homeDir = paths.user.darwinHome;
  flakeRoot = paths.darwin.home.nixConfig;
  codexRoot = paths.darwin.agents.codex.root;
  profileConfig = paths.darwin.agents.codex.profileConfig;
  profiles = [
    "api"
    "chatgpt"
  ];

  # MARKETPLACE
  # =========================
  # Claude-mem supplies its own Codex marketplace metadata and plugin
  # manifest. The pinned flake input is therefore the marketplace root.

  marketplaceName = "claude-mem-local";
  marketplaceRoot = inputs.claude-mem;
  pluginId = "claude-mem@${marketplaceName}";

  # SYNC
  # =========================
  # Register the upstream marketplace and enable the plugin in both
  # isolated Codex registries. The runtime cache remains Codex-managed.

  syncClaudeMem = pkgs.writeShellApplication {
    name = "codex-sync-claude-mem";

    runtimeInputs = [
      pkgs.gawk
      pkgs.jq
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      marketplace_name=${lib.escapeShellArg marketplaceName}
      marketplace_root=${lib.escapeShellArg marketplaceRoot}
      plugin_id=${lib.escapeShellArg pluginId}

      plugin_is_installed() {
        profile="$1"

        CODEX_CLI="$codex_cli" \
          "$codex_profile" cli "$profile" \
          plugin list \
          --marketplace "$marketplace_name" \
          --json \
          | ${pkgs.jq}/bin/jq -e \
              --arg plugin_id "$plugin_id" \
              'any(.installed[]?; .pluginId == $plugin_id and .installed and .enabled)' \
          >/dev/null
      }

      sync_profile() {
        profile="$1"
        marketplace_changed=false

        configured_root="$(
          CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            plugin marketplace list \
            | ${pkgs.gawk}/bin/awk \
                -v name="$marketplace_name" \
                '$1 == name { print $2; exit }'
        )"

        if test "$configured_root" != "$marketplace_root"; then
          marketplace_changed=true

          if test -n "$configured_root"; then
            CODEX_CLI="$codex_cli" \
              "$codex_profile" cli "$profile" \
              plugin marketplace remove "$marketplace_name"
          fi

          CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            plugin marketplace add "$marketplace_root"
        fi

        if test "$marketplace_changed" = true || ! plugin_is_installed "$profile"; then
          CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            plugin add "$plugin_id"
        fi
      }

      ${lib.concatMapStringsSep "\n" (profile: "sync_profile ${lib.escapeShellArg profile}") profiles}
    '';
  };

  # UPDATE
  # =========================
  # Update only Claude-mem's pinned source. update-codex-extensions
  # performs the single rebuild after all extension updates succeed.

  updateClaudeMem = pkgs.writeShellApplication {
    name = "update-codex-claude-mem";

    runtimeInputs = [
      pkgs.git
      pkgs.nix
    ];

    text = ''
      set -Eeuo pipefail

      flake_root=${lib.escapeShellArg flakeRoot}
      lock_file="$flake_root/flake.lock"

      if ! git -C "$flake_root" diff --quiet -- "$lock_file"; then
        printf 'Refusing to update Claude-mem: flake.lock has uncommitted changes.\n' >&2
        printf 'Review or commit the lock-file changes, then run this command again.\n' >&2
        exit 1
      fi

      nix flake lock \
        --update-input claude-mem \
        "$flake_root"
    '';
  };
in
{
  imports = [
    ./claude-mem-settings.nix

    ./standup.nix
    ./what-the.nix
    ./make-plan.nix
    ./mem-search.nix
    ./pathfinder.nix
    ./mode-creator.nix
  ];

  # COMMANDS
  # =========================
  # The manual synchronizer repairs either profile without a rebuild;
  # the updater is discovered by update-codex-extensions.

  environment.systemPackages = [
    syncClaudeMem
    updateClaudeMem
  ];

  # ACTIVATION
  # =========================
  # Only Codex's marketplace registry changes here. Claude-mem's mutable
  # database, cache, and worker state are deliberately untouched.

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    /usr/bin/sudo \
      -u ${userName} \
      /usr/bin/env \
      HOME=${homeDir} \
      CODEX_PROFILE_HOME_ROOT=${codexRoot} \
      CODEX_PROFILE_CONFIG_HOME=${profileConfig} \
      ${syncClaudeMem}/bin/codex-sync-claude-mem
  '';
}
