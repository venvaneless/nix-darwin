# CODEX: CODEBASE MEMORY MCP
# =========================
# Package and register the Codebase Memory MCP server

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
  dataDir = "${codexRoot}/shared/codebase-memory-mcp";

  profiles = [
    "api"
    "chatgpt"
  ];

  # PACKAGE
  # =========================
  # Install the verified Apple-Silicon release archive in the Nix store

  release = builtins.fromJSON (builtins.readFile ../codebase-memory-mcp-release.json);

  codebaseMemoryMcp = pkgs.stdenvNoCC.mkDerivation {
    pname = "codebase-memory-mcp";
    version = release.version;

    src = pkgs.fetchurl {
      url = release.url;
      sha256 = release.fileSha256;
    };

    dontUnpack = true;
    nativeBuildInputs = [
      pkgs.findutils
      pkgs.gnutar
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p extracted
      binary="$(
        ${pkgs.gnutar}/bin/tar -xzf "$src" -C extracted
        ${pkgs.findutils}/bin/find \
          extracted \
          -type f \
          -name codebase-memory-mcp \
          -print \
          -quit
      )"

      test -n "$binary"

      install -Dm755 \
        "$binary" \
        "$out/bin/codebase-memory-mcp"

      runHook postInstall
    '';

    meta = {
      description = "Codebase knowledge-graph MCP server";
      homepage = "https://github.com/DeusData/codebase-memory-mcp";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
      mainProgram = "codebase-memory-mcp";
    };
  };

  # SYNC
  # =========================
  # Register the store-backed MCP server with both Codex profiles

  syncCodebaseMemory = pkgs.writeShellApplication {
    name = "codex-sync-codebase-memory-mcp";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      mcp_binary="${codebaseMemoryMcp}/bin/codebase-memory-mcp"
      mcp_data_dir="${dataDir}"

      mkdir -p -- "$mcp_data_dir"

      mcp_matches_declaration() {
        profile="$1"

        CODEX_CLI="$codex_cli" \
          "$codex_profile" cli "$profile" \
          mcp get codebase-memory-mcp \
          --json \
          2>/dev/null \
          | ${pkgs.jq}/bin/jq -e \
              --arg mcp_binary "$mcp_binary" \
              --arg mcp_data_dir "$mcp_data_dir" \
              '.enabled == true
                and .transport.type == "stdio"
                and .transport.command == $mcp_binary
                and .transport.args == []
                and .transport.env == { "CBM_CACHE_DIR": $mcp_data_dir }
                and .transport.env_vars == []
                and .transport.cwd == null' \
          >/dev/null
      }

      sync_profile() {
        profile="$1"

        if mcp_matches_declaration "$profile"; then
          return
        fi

        if CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            mcp get codebase-memory-mcp \
            >/dev/null 2>&1; then
          CODEX_CLI="$codex_cli" \
            "$codex_profile" cli "$profile" \
            mcp remove codebase-memory-mcp
        fi

        CODEX_CLI="$codex_cli" \
          "$codex_profile" cli "$profile" \
          mcp add codebase-memory-mcp \
          --env "CBM_CACHE_DIR=$mcp_data_dir" \
          -- "$mcp_binary"
      }

      ${lib.concatMapStringsSep "\n" (profile: "sync_profile ${lib.escapeShellArg profile}") profiles}
    '';
  };
in
{
  environment.systemPackages = [
    codebaseMemoryMcp
    syncCodebaseMemory
  ];

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    /usr/bin/sudo \
      -u ${userName} \
      /usr/bin/env \
      HOME=${homeDir} \
      CODEX_PROFILE_HOME_ROOT=${codexRoot} \
      CODEX_PROFILE_CONFIG_HOME=${homeDir}/.config/codex-profile \
      ${syncCodebaseMemory}/bin/codex-sync-codebase-memory-mcp
  '';
}
