# CODEX: SCHOLARBRAIN
# =========================
# Package, install, and register the ScholarBrain Codex plugin

{
  inputs,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:

let
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
  # Wrap ScholarBrain's portable agent skill as a valid Codex plugin.

  scholarBrainManifest = pkgs.writeText "scholarbrain-plugin.json" ''
    {
      "name": "scholarbrain",
      "version": "0.1.0",
      "description": "Operate an Obsidian vault as a living second brain.",
      "author": { "name": "SHzzzAyys" },
      "repository": "https://github.com/SHzzzAyys/scholarbrain",
      "license": "MIT",
      "skills": "./skills/",
      "interface": {
        "displayName": "ScholarBrain",
        "shortDescription": "Operate an Obsidian vault as a second brain.",
        "longDescription": "Codex skill for operating and maintaining an Obsidian second brain.",
        "developerName": "SHzzzAyys",
        "category": "Productivity",
        "capabilities": ["Write"],
        "websiteURL": "https://github.com/SHzzzAyys/scholarbrain",
        "defaultPrompt": [
          "Use ScholarBrain to organize my Obsidian vault."
        ],
        "brandColor": "#7C3AED"
      }
    }
  '';

  scholarBrain = pkgs.runCommand "codex-scholarbrain" { } ''
    mkdir -p "$out/skills/scholarbrain"

    cp -R \
      ${inputs.scholarbrain}/. \
      "$out/skills/scholarbrain/"

    install -Dm444 \
      ${scholarBrainManifest} \
      "$out/.codex-plugin/plugin.json"
  '';

  # MARKETPLACE
  # =========================
  # Local marketplace exposing the packaged ScholarBrain plugin.

  marketplaceMetadata = pkgs.writeText "scholarbrain-marketplace.json" ''
    {
      "name": "ven-scholarbrain",
      "interface": {
        "displayName": "ScholarBrain"
      },
      "plugins": [
        {
          "name": "scholarbrain",
          "source": {
            "source": "local",
            "path": "./plugins/scholarbrain"
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

  scholarBrainMarketplace = pkgs.runCommand "codex-scholarbrain-marketplace" { } ''
    mkdir -p \
      "$out/.agents/plugins" \
      "$out/plugins"

    ln -s \
      ${scholarBrain} \
      "$out/plugins/scholarbrain"

    install -Dm444 \
      ${marketplaceMetadata} \
      "$out/.agents/plugins/marketplace.json"
  '';

  # SYNC
  # =========================
  # Register the plugin with both shared Codex profiles.

  syncScholarBrain = pkgs.writeShellApplication {
    name = "codex-sync-scholarbrain";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.jq
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      marketplace_name="ven-scholarbrain"
      marketplace_root="${scholarBrainMarketplace}"
      plugin_id="scholarbrain@$marketplace_name"

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

    rm -rf "${sharedPlugins}/scholarbrain"

    ln -s \
      "${scholarBrain}" \
      "${sharedPlugins}/scholarbrain"

    chown -h \
      ${userName}:staff \
      "${sharedPlugins}/scholarbrain"

    /usr/bin/sudo \
      -u ${userName} \
      /usr/bin/env \
      HOME=${homeDir} \
      CODEX_PROFILE_HOME_ROOT=${codexRoot} \
      CODEX_PROFILE_CONFIG_HOME=${homeDir}/.config/codex-profile \
      ${syncScholarBrain}/bin/codex-sync-scholarbrain
  '';
}
