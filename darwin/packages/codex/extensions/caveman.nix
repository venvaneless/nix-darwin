# CODEX: CAVEMAN
# =========================
# Fetch and install the Caveman Codex plugin

{ lib, pkgs, unstablePkgs, ... }:

let
  userName = "ven";
  homeDir = "/Users/${userName}";

  codexRoot = "${homeDir}/.config/codex";
  sharedPlugins = "${codexRoot}/shared/plugins";

  profiles = [
    "api"
    "chatgpt"
  ];


  # SOURCE
  # =========================
  # Version information updated by update-codex-extensions

  source = builtins.fromJSON (
    builtins.readFile ./caveman-source.json
  );

  cavemanSource = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";

    rev = source.rev;
    hash = source.hash;
  };


  # MARKETPLACE
  # =========================
  # Local Codex marketplace containing only Caveman

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
      ${cavemanSource}/plugins/caveman \
      "$out/plugins/caveman"

    install -Dm444 \
      ${marketplaceMetadata} \
      "$out/.agents/plugins/marketplace.json"
  '';


  # SYNC
  # =========================
  # Register Caveman with every Codex profile

  syncCaveman = pkgs.writeShellApplication {
    name = "codex-sync-caveman";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      marketplace_name="ven-caveman"
      marketplace_root="${cavemanMarketplace}"

      sync_profile() {
        profile="$1"

        configured_root="$(
          CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            plugin marketplace list \
            | ${pkgs.gawk}/bin/awk \
                -v name="$marketplace_name" \
                '$1 == name { print $2; exit }'
        )"

        if test "$configured_root" != "$marketplace_root"; then
          if test -n "$configured_root"; then
            CODEX_CLI="$codex_cli" \
              "$codex_profile" cli "$profile" \
              plugin marketplace remove "$marketplace_name"
          fi

          CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            plugin marketplace add "$marketplace_root"
        fi

        CODEX_CLI="$codex_cli" \
          "$codex_profile" cli "$profile" \
          plugin add "caveman@$marketplace_name"

        printf 'Caveman synchronized for Codex profile: %s\n' "$profile"
      }

      ${lib.concatMapStringsSep "\n" (
        profile: "sync_profile ${lib.escapeShellArg profile}"
      ) profiles}
    '';
  };
in
{
  # CODEX: CAVEMAN PLUGIN
  # =========================
  # Make the plugin source visible through the shared plugin directory

  system.activationScripts.codexCaveman.text = lib.mkAfter ''
    echo "[nix-darwin][codex] Configuring Caveman..."

    mkdir -p "${sharedPlugins}"

    rm -rf "${sharedPlugins}/caveman"

    ln -s \
      "${cavemanSource}/plugins/caveman" \
      "${sharedPlugins}/caveman"

    chown -h \
      ${userName}:staff \
      "${sharedPlugins}/caveman"


    /usr/bin/sudo \
      -u ${userName} \
      /usr/bin/env \
      HOME=${homeDir} \
      CODEX_PROFILE_HOME_ROOT=${codexRoot} \
      CODEX_PROFILE_CONFIG_HOME=${homeDir}/.config/codex-profile \
      ${syncCaveman}/bin/codex-sync-caveman
  '';


  # CODEX: EXTENSION UPDATE
  # =========================
  # Plugin-specific updater consumed by update.nix

  codex.extensionUpdaters = [
    ''
      echo "Checking Caveman..."

      repo="JuliusBrussee/caveman"
      source_file="$flake_root/darwin/packages/codex/extensions/caveman-source.json"

      latest_json="$(
        ${pkgs.curl}/bin/curl \
          -fsSL \
          "https://api.github.com/repos/$repo/releases/latest"
      )"

      latest_version="$(
        printf '%s' "$latest_json" \
          | ${pkgs.jq}/bin/jq -r '.tag_name'
      )"

      latest_rev="$(
        ${pkgs.git}/bin/git \
          ls-remote \
          "https://github.com/$repo.git" \
          "refs/tags/$latest_version^{}" \
          | ${pkgs.gawk}/bin/awk 'NR == 1 { print $1 }'
      )"

      if test -z "$latest_rev"; then
        latest_rev="$(
          ${pkgs.git}/bin/git \
            ls-remote \
            "https://github.com/$repo.git" \
            "refs/tags/$latest_version" \
            | ${pkgs.gawk}/bin/awk 'NR == 1 { print $1 }'
        )"
      fi

      current_rev="$(
        ${pkgs.jq}/bin/jq -r '.rev' "$source_file"
      )"

      if test "$current_rev" = "$latest_rev"; then
        echo "Caveman is already current."
      else
        prefetch="$(
          ${pkgs.nix-prefetch-github}/bin/nix-prefetch-github \
            JuliusBrussee \
            caveman \
            --rev "$latest_rev"
        )"

        new_hash="$(
          printf '%s' "$prefetch" \
            | ${pkgs.jq}/bin/jq -r '.hash // .sha256'
        )"

        ${pkgs.jq}/bin/jq \
          --arg version "''${latest_version#v}" \
          --arg rev "$latest_rev" \
          --arg hash "$new_hash" \
          '
            .version = $version
            | .rev = $rev
            | .hash = $hash
          ' \
          "$source_file" \
          > "$source_file.tmp"

        ${pkgs.coreutils}/bin/mv \
          "$source_file.tmp" \
          "$source_file"

        echo "Caveman updated: $latest_version"
      fi
    ''
  ];
}