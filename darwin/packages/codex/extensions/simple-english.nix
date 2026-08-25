# CODEX: SIMPLE ENGLISH
# =========================
# Package, install, and register the Simple English Codex plugin

{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # ---- Variables from options/default.nix
  # The unstable package set is built once there, under the same
  # nixpkgs policy as the stable set.
  inherit (import ../../../../options { inherit inputs pkgs; }) unstablePkgs;

  userName = "ven";
  homeDir = "/Users/${userName}";

  codexRoot = "${homeDir}/.config/codex";
  sharedPlugins = "${codexRoot}/shared/plugins";

  profiles = [
    "api"
    "chatgpt"
  ];

  # PACKAGE
  # =========================
  # Wrap Simple English's standalone skill as a valid Codex plugin

  simpleEnglishManifest = pkgs.writeText "simple-english-plugin.json" ''
    {
      "name": "simple-english",
      "version": "1.0.0",
      "description": "Write technical documentation in Simplified Technical English.",
      "author": { "name": "AminBlg" },
      "repository": "https://github.com/AminBlg/SimpleEnglish",
      "license": "MIT",
      "skills": "./skills/"
    }
  '';

  simpleEnglish = pkgs.runCommand "codex-simple-english" { } ''
    mkdir -p "$out/skills"

    ln -s \
      ${inputs.simple-english}/skills/simple-english \
      "$out/skills/simple-english"

    install -Dm444 \
      ${simpleEnglishManifest} \
      "$out/.codex-plugin/plugin.json"
  '';

  # MARKETPLACE
  # =========================
  # Local marketplace exposing the packaged Simple English plugin

  marketplaceMetadata = pkgs.writeText "simple-english-marketplace.json" ''
    {
      "name": "ven-simple-english",
      "interface": {
        "displayName": "Simple English"
      },
      "plugins": [
        {
          "name": "simple-english",
          "source": {
            "source": "local",
            "path": "./plugins/simple-english"
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

  simpleEnglishMarketplace = pkgs.runCommand "codex-simple-english-marketplace" { } ''
    mkdir -p \
      "$out/.agents/plugins" \
      "$out/plugins"

    ln -s \
      ${simpleEnglish} \
      "$out/plugins/simple-english"

    install -Dm444 \
      ${marketplaceMetadata} \
      "$out/.agents/plugins/marketplace.json"
  '';

  # SYNC
  # =========================
  # Register the plugin with both Codex profiles

  syncSimpleEnglish = pkgs.writeShellApplication {
    name = "codex-sync-simple-english";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.jq
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      marketplace_name="ven-simple-english"
      marketplace_root="${simpleEnglishMarketplace}"
      plugin_id="simple-english@$marketplace_name"

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
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    mkdir -p "${sharedPlugins}"

    rm -rf "${sharedPlugins}/simple-english"

    ln -s \
      "${simpleEnglish}" \
      "${sharedPlugins}/simple-english"

    chown -h \
      ${userName}:staff \
      "${sharedPlugins}/simple-english"

    /usr/bin/sudo \
      -u ${userName} \
      /usr/bin/env \
      HOME=${homeDir} \
      CODEX_PROFILE_HOME_ROOT=${codexRoot} \
      CODEX_PROFILE_CONFIG_HOME=${homeDir}/.config/codex-profile \
      ${syncSimpleEnglish}/bin/codex-sync-simple-english
  '';
}
