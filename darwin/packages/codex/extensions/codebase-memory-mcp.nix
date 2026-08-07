# CODEX: CODEBASE MEMORY MCP
# =========================
# Install and register the Codebase Memory MCP server

{ lib, pkgs, unstablePkgs, ... }:

let
  profiles = [
    "chatgpt"
    "api"
  ];

  dataDir =
    "/Users/ven/.config/codex/shared/codebase-memory-mcp";

  installCodebaseMemory = pkgs.writeShellApplication {
    name = "install-codebase-memory-mcp";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.findutils
      pkgs.gnutar
      pkgs.jq
    ];

    text = ''
      set -Eeuo pipefail

      install_root="/Users/ven/.config/codex/shared/codebase-memory-mcp/bin"
      temporary_dir="$(${pkgs.coreutils}/bin/mktemp -d)"

      cleanup() {
        rm -rf -- "$temporary_dir"
      }

      trap cleanup EXIT


      # GITHUB RELEASE
      # =========================
      # Read the latest upstream release metadata
      release_json="$(
        ${pkgs.curl}/bin/curl \
          --fail \
          --silent \
          --show-error \
          --location \
          https://api.github.com/repos/DeusData/codebase-memory-mcp/releases/latest
      )"

      release_url="$(
        printf '%s' "$release_json" \
          | ${pkgs.jq}/bin/jq -r \
              '.assets[]
               | select(.name == "codebase-memory-mcp-darwin-arm64.tar.gz")
               | .browser_download_url'
      )"

      if test -z "$release_url" || test "$release_url" = "null"; then
        printf 'Could not find the Darwin ARM64 Codebase Memory release.\n' >&2
        exit 1
      fi


      # DOWNLOAD
      # =========================
      # Download and extract the current release
      archive="$temporary_dir/codebase-memory-mcp.tar.gz"

      ${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --output "$archive" \
        "$release_url"

      mkdir -p "$temporary_dir/extracted"

      ${pkgs.gnutar}/bin/tar \
        -xzf "$archive" \
        -C "$temporary_dir/extracted"


      # INSTALL
      # =========================
      # Find and install the MCP executable
      binary="$(
        ${pkgs.findutils}/bin/find \
          "$temporary_dir/extracted" \
          -type f \
          -name codebase-memory-mcp \
          -print \
          -quit
      )"

      if test -z "$binary"; then
        printf 'Could not find codebase-memory-mcp in the release archive.\n' >&2
        exit 1
      fi

      mkdir -p "$install_root"

      install \
        -m755 \
        "$binary" \
        "$install_root/codebase-memory-mcp"

      printf 'Codebase Memory MCP installed.\n'
    '';
  };


  syncCodebaseMemory = pkgs.writeShellApplication {
    name = "sync-codebase-memory-mcp";

    runtimeInputs = [
      pkgs.coreutils
    ];

    text = ''
      set -Eeuo pipefail

      codex_profile="${pkgs.codex-profile}/bin/codex-profile"
      codex_cli="${unstablePkgs.codex}/bin/codex"

      mcp_binary="/Users/ven/.config/codex/shared/codebase-memory-mcp/bin/codebase-memory-mcp"
      mcp_data_dir="${dataDir}"

      mkdir -p -- "$mcp_data_dir"


      sync_profile() {
        local profile="$1"

        if ! test -d "/Users/ven/.config/codex/$profile"; then
          printf 'Codex profile does not exist: %s\n' "$profile" >&2
          return 1
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

        printf \
          'Codebase Memory MCP synchronized for profile: %s\n' \
          "$profile"
      }


      ${lib.concatMapStringsSep "\n" (
        profile:
          "sync_profile ${lib.escapeShellArg profile}"
      ) profiles}
    '';
  };
in
{
  environment.systemPackages = [
    installCodebaseMemory
    syncCodebaseMemory
  ];

  system.activationScripts.codexCodebaseMemory.text = lib.mkAfter ''
    echo "[nix-darwin][codex] Installing/updating Codebase Memory MCP..."

    /usr/bin/sudo \
      -u ven \
      /usr/bin/env \
      HOME=/Users/ven \
      ${installCodebaseMemory}/bin/install-codebase-memory-mcp

    /usr/bin/sudo \
      -u ven \
      /usr/bin/env \
      HOME=/Users/ven \
      CODEX_PROFILE_HOME_ROOT=/Users/ven/.config/codex \
      CODEX_PROFILE_CONFIG_HOME=/Users/ven/.config/codex-profile \
      ${syncCodebaseMemory}/bin/sync-codebase-memory-mcp
  '';
}