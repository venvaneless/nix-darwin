# CODEX: CAVEMAN
# =========================
# Package, install, register, and update the Caveman Codex plugin

{
  inputs,
  lib,
  options,
  pkgs,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ SHARED CONFIGURATION ------ #
  # Keep Caveman aligned with the Codex profiles and path definitions.

  # ---- Variables from options/default.nix
  # The unstable package set is built once there, under the same
  # nixpkgs policy as the stable set.
  helpers = import ../../../../options { inherit inputs lib options pkgs; };
  inherit (helpers) unstablePkgs paths;

  userName = paths.user.name;
  homeDir = paths.user.darwinHome;
  flakeRoot = paths.darwin.home.nixConfig;
  codexRoot = paths.darwin.agents.codex.root;
  profileConfig = paths.darwin.agents.codex.profileConfig;
  sharedPlugins = paths.darwin.agents.codex.sharedPlugins;
  cavemanLink = "${sharedPlugins}/caveman";

  profiles = [
    "api"
    "chatgpt"
  ];

  # PACKAGE
  # =========================
  # Build the plugin from the flake input so its revision stays in the
  # shared lock file beside the other declarative Codex extensions.

  caveman = pkgs.runCommand "codex-caveman" { } ''
    mkdir -p "$out"

    cp -R \
      ${inputs.caveman}/plugins/caveman/. \
      "$out/"
  '';

  # MARKETPLACE
  # =========================
  # Local marketplace exposing the packaged Caveman plugin

  marketplaceMetadata = pkgs.writeText "caveman-marketplace.json" ''
    {
      "name": "ven-caveman",
      "interface": {
        "displayName": "Caveman"
      },
      "plugins": [
        {
          "name": "caveman",
          "source": {
            "source": "local",
            "path": "./plugins/caveman"
          },
          "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL"
          },
          "category": "Productivity"
        }
      ]
    }
  '';

  cavemanMarketplace = pkgs.runCommand "codex-caveman-marketplace" { } ''
    mkdir -p \
      "$out/.agents/plugins" \
      "$out/plugins"

    ln -s \
      ${caveman} \
      "$out/plugins/caveman"

    install -Dm444 \
      ${marketplaceMetadata} \
      "$out/.agents/plugins/marketplace.json"
  '';

  # SYNC
  # =========================
  # Register the plugin with both Codex profiles

  syncCaveman = pkgs.writeShellApplication {
    name = "codex-sync-caveman";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.jq
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      marketplace_name="ven-caveman"
      marketplace_root="${cavemanMarketplace}"
      plugin_id="caveman@$marketplace_name"

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
  # Update only Caveman's pinned source. update-codex-extensions performs
  # the single rebuild after every declared extension updater succeeds.

  updateCaveman = pkgs.writeShellApplication {
    name = "update-codex-caveman";

    runtimeInputs = [
      pkgs.git
      pkgs.nix
    ];

    text = ''
      set -Eeuo pipefail

      flake_root=${lib.escapeShellArg flakeRoot}
      lock_file="$flake_root/flake.lock"

      if ! git -C "$flake_root" diff --quiet -- "$lock_file"; then
        printf 'Refusing to update Caveman: flake.lock has uncommitted changes.\n' >&2
        printf 'Review or commit the lock-file changes, then run this command again.\n' >&2
        exit 1
      fi

      nix flake lock \
        --update-input caveman \
        "$flake_root"
    '';
  };
in
{
  # COMMANDS
  # =========================
  # The manual synchronizer repairs both profile registries without a
  # rebuild; the updater is discovered by update-codex-extensions.

  environment.systemPackages = [
    syncCaveman
    updateCaveman
  ];

  # ACTIVATION
  # =========================
  # Expose exactly one shared Caveman source to both profile plugin links.

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    mkdir -p "${sharedPlugins}"

    if [ -L "${cavemanLink}" ]; then
      current_target="$(${pkgs.coreutils}/bin/readlink -- "${cavemanLink}")"

      case "$current_target" in
        "${paths.nixPaths.store}/"*codex-caveman*)
          ${paths.darwin.system.bin.rm} -f -- "${cavemanLink}"
          ;;
        *)
          echo "[nix-darwin][codex] Refusing to replace an unrelated Caveman link: ${cavemanLink}" >&2
          exit 1
          ;;
      esac
    elif [ -e "${cavemanLink}" ]; then
      echo "[nix-darwin][codex] Refusing to replace a non-link Caveman path: ${cavemanLink}" >&2
      exit 1
    fi

    ln -s \
      "${caveman}" \
      "${cavemanLink}"

    ${paths.darwin.system.bin.chown} -h \
      ${userName}:staff \
      "${cavemanLink}"

    /usr/bin/sudo \
      -u ${userName} \
      /usr/bin/env \
      HOME=${homeDir} \
      CODEX_PROFILE_HOME_ROOT=${codexRoot} \
      CODEX_PROFILE_CONFIG_HOME=${profileConfig} \
      ${syncCaveman}/bin/codex-sync-caveman
  '';
}
