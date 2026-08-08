# CODEX: CAVEMAN
# =========================
# Package, install, register, and update the Caveman Codex plugin

{
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
  # Caveman source and updater metadata live together

  caveman = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "codex-caveman";
    version = "1.8.2";

    src = pkgs.fetchFromGitHub {
      owner = "JuliusBrussee";
      repo = "caveman";

      rev = "v${version}";
      hash = "sha256-Jlfas2MPoQx3pOw+yKCta8kYlOEY27SP5NXJtSL+GGI=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"

      cp -R \
        plugins/caveman/. \
        "$out/"

      runHook postInstall
    '';

    passthru.updateScript = pkgs.nix-update-script { };

    meta = {
      description = "Caveman plugin for Codex";
      homepage = "https://github.com/JuliusBrussee/caveman";
      platforms = lib.platforms.all;
    };
  };


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
      }

      ${lib.concatMapStringsSep "\n" (
        profile: "sync_profile ${lib.escapeShellArg profile}"
      ) profiles}
    '';
  };
in
{
  system.activationScripts.codexCaveman.text = lib.mkAfter ''
    echo "[nix-darwin][codex] Installing Caveman..."

    mkdir -p "${sharedPlugins}"

    rm -rf "${sharedPlugins}/caveman"

    ln -s \
      "${caveman}" \
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
}