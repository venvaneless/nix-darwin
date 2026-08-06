# darwin/packages/codex/extensions.nix
#
# CODEX: DECLARATIVE EXTENSIONS
# =====================================================================
# Pins Codex plugin sources and builds codebase-memory-mcp with Nix.
# The manually run codex-sync-extensions command reconciles the declared
# marketplace and MCP entries into both mutable Codex profile configurations.
# =====================================================================

{ inputs, pkgs, unstablePkgs, ... }:

let
  # Keep the two Codex profiles aligned while retaining their independent UI state.
  profiles = [ "chatgpt" "api" ];
  sharedRoot = "/Users/ven/.config/codex/shared";
  codebaseMemoryDataDir = "${sharedRoot}/codebase-memory-mcp";

  # Build the upstream C implementation from the flake-locked source tree.
  codebaseMemoryMcp = pkgs.stdenv.mkDerivation {
    pname = "codebase-memory-mcp";
    version = "git";
    src = inputs.codebase-memory-mcp;

    nativeBuildInputs = [ pkgs.gnumake ];
    buildInputs = [ pkgs.zlib ];

    # The standard build excludes the optional graph UI and its Node dependency.
    buildPhase = ''
      runHook preBuild

      make -f Makefile.cbm cbm

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 \
        build/c/codebase-memory-mcp \
        "$out/bin/codebase-memory-mcp"

      runHook postInstall
    '';

    meta = {
      description = "Codebase knowledge-graph MCP server";
      homepage = "https://github.com/DeusData/codebase-memory-mcp";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.unix;
      mainProgram = "codebase-memory-mcp";
    };
  };

  # Wrap SimpleEnglish's standalone Agent Skill as a valid Codex plugin.
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

  # One local marketplace makes source revisions deterministic for both profiles.
  marketplaceMetadata = pkgs.writeText "ven-codex-extensions-marketplace.json" ''
    {
      "name": "ven-codex-extensions",
      "interface": { "displayName": "Ven Codex Extensions" },
      "plugins": [
        {
          "name": "caveman",
          "source": { "source": "local", "path": "./plugins/caveman" },
          "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
          "category": "Productivity"
        },
        {
          "name": "simple-english",
          "source": { "source": "local", "path": "./plugins/simple-english" },
          "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
          "category": "Productivity"
        }
      ]
    }
  '';

  codexMarketplace = pkgs.runCommand "ven-codex-extensions-marketplace" { } ''
    mkdir -p "$out/.agents/plugins" "$out/plugins/simple-english/.codex-plugin"

    ln -s ${inputs.caveman}/plugins/caveman "$out/plugins/caveman"
    ln -s ${inputs.simple-english}/skills/simple-english \
      "$out/plugins/simple-english/skills"

    install -Dm444 \
      ${simpleEnglishManifest} \
      "$out/plugins/simple-english/.codex-plugin/plugin.json"
    install -Dm444 \
      ${marketplaceMetadata} \
      "$out/.agents/plugins/marketplace.json"
  '';

  codexSyncExtensions = pkgs.writeShellApplication {
    name = "codex-sync-extensions";

    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.gnugrep ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"
      marketplace_name="ven-codex-extensions"
      marketplace_root="${codexMarketplace}"
      mcp_binary="${codebaseMemoryMcp}/bin/codebase-memory-mcp"
      mcp_data_dir="${codebaseMemoryDataDir}"

      mkdir -p -- "$mcp_data_dir"

      sync_profile() {
        local profile="$1"
        local configured_root=""

        if ! test -d "/Users/ven/.config/codex/$profile"; then
          printf 'Codex profile does not exist: %s\n' "$profile" >&2
          return 1
        fi

        configured_root="$(
          CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
            plugin marketplace list \
            | ${pkgs.gawk}/bin/awk -v name="$marketplace_name" \
                '$1 == name { print $2; exit }'
        )"

        if test "$configured_root" != "$marketplace_root"; then
          if test -n "$configured_root"; then
            CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
              plugin marketplace remove "$marketplace_name"
          fi

          CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
            plugin marketplace add "$marketplace_root"
        fi

        CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
          plugin add "caveman@$marketplace_name"
        CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
          plugin add "simple-english@$marketplace_name"

        if CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
            mcp get codebase-memory-mcp >/dev/null 2>&1; then
          CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
            mcp remove codebase-memory-mcp
        fi

        CODEX_CLI="$codex_cli" "$codex_profile" cli "$profile" \
          mcp add codebase-memory-mcp \
          --env "CBM_CACHE_DIR=$mcp_data_dir" \
          -- "$mcp_binary"

        printf 'Synchronized Codex extensions for profile: %s\n' "$profile"
      }

      ${pkgs.lib.concatMapStringsSep "\n" (profile: "sync_profile ${pkgs.lib.escapeShellArg profile}") profiles}
    '';
  };
in
{
  environment.systemPackages = [
    codebaseMemoryMcp
    codexSyncExtensions
  ];
}
