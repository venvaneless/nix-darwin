# darwin/packages/codex/extensions.nix
#
# CODEX: DECLARATIVE EXTENSIONS
# =====================================================================
# Pins Codex plugin sources and builds codebase-memory-mcp with Nix.
# The manually run codex-sync-extensions command reconciles the declared
# marketplace and MCP entries into both mutable Codex profile configurations.
# =====================================================================

{ inputs, lib, pkgs, unstablePkgs, ... }:

let
  # Keep the two Codex profiles aligned while retaining their independent UI state.
  profiles = [ "chatgpt" "api" ];
  sharedRoot = "/Users/ven/.config/codex/shared";
  codebaseMemoryDataDir = "${sharedRoot}/codebase-memory-mcp";

  # This lock is updated by update-codex-extensions from GitHub release metadata.
  codebaseMemoryRelease = builtins.fromJSON (
    builtins.readFile ./codebase-memory-mcp-release.json
  );

  # Install the upstream Apple-Silicon release archive verified by its SHA-256.
  codebaseMemoryMcp = pkgs.stdenvNoCC.mkDerivation {
    pname = "codebase-memory-mcp";
    version = codebaseMemoryRelease.version;
    src = pkgs.fetchurl {
      url = codebaseMemoryRelease.url;
      sha256 = codebaseMemoryRelease.fileSha256;
    };

    dontUnpack = true;
    nativeBuildInputs = [ pkgs.findutils pkgs.gnutar ];

    installPhase = ''
      runHook preInstall

      mkdir -p extracted
      ${pkgs.gnutar}/bin/tar -xzf "$src" -C extracted

      binary="$(${pkgs.findutils}/bin/find extracted -type f -name codebase-memory-mcp -print -quit)"
      test -n "$binary"

      install -Dm755 \
        "$binary" \
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

  # Update only the declared Codex sources, then rebuild and synchronize them.
  codexUpdateExtensions = pkgs.writeShellApplication {
    name = "update-codex-extensions";

    runtimeInputs = [ pkgs.coreutils pkgs.git pkgs.gh pkgs.jq pkgs.nix ];

    text = ''
      set -Eeuo pipefail

      flake_root="/Users/ven/.config/nix/nix-config"
      lock_file="$flake_root/flake.lock"
      release_lock="$flake_root/darwin/packages/codex/codebase-memory-mcp-release.json"

      if ! ${pkgs.git}/bin/git -C "$flake_root" diff --quiet -- "$lock_file"; then
        printf 'Refusing to update Codex extensions: flake.lock has uncommitted changes.\n' >&2
        printf 'Review or commit the lock-file changes, then run this command again.\n' >&2
        exit 1
      fi

      cd -- "$flake_root"

      ${pkgs.nix}/bin/nix flake lock \
        --update-input caveman \
        --update-input simple-english

      release_json="$(${pkgs.gh}/bin/gh api repos/DeusData/codebase-memory-mcp/releases/latest)"
      release_tag="$(printf '%s' "$release_json" | ${pkgs.jq}/bin/jq -r '.tag_name')"
      release_url="$(printf '%s' "$release_json" | ${pkgs.jq}/bin/jq -r '.assets[] | select(.name == "codebase-memory-mcp-darwin-arm64.tar.gz") | .browser_download_url')"
      release_digest="$(printf '%s' "$release_json" | ${pkgs.jq}/bin/jq -r '.assets[] | select(.name == "codebase-memory-mcp-darwin-arm64.tar.gz") | .digest // empty')"

      if test -z "$release_url" || test -z "$release_digest" || test "$release_digest" = "null"; then
        printf 'Upstream latest release has no checksum-bearing Darwin ARM64 archive.\n' >&2
        exit 1
      fi

      release_hash="''${release_digest#sha256:}"
      temporary_lock="$(${pkgs.coreutils}/bin/mktemp "$release_lock.XXXXXXXX")"
      printf '{\n  "version": "%s",\n  "url": "%s",\n  "fileSha256": "%s"\n}\n' \
        "''${release_tag#v}" "$release_url" "$release_hash" >"$temporary_lock"
      ${pkgs.coreutils}/bin/mv -- "$temporary_lock" "$release_lock"

      if ${pkgs.git}/bin/git diff --quiet -- flake.lock; then
        printf 'Codex extension sources are already current.\n'
        exit 0
      fi

      printf 'Codex extension sources changed; rebuilding nix-darwin.\n'
      exec /usr/bin/sudo -H /run/current-system/sw/bin/darwin-rebuild switch \
        --flake "$flake_root#macbook"
    '';
  };
in
{
  # Synchronize both mutable Codex profile registries after a successful switch.
  # The sources and MCP binary are already local Nix store paths at activation.
  system.activationScripts.codexExtensions.text = lib.mkAfter ''
    if ! /usr/bin/sudo -u ven /usr/bin/env \
      HOME=/Users/ven \
      CODEX_PROFILE_HOME_ROOT=/Users/ven/.config/codex \
      CODEX_PROFILE_CONFIG_HOME=/Users/ven/.config/codex-profile \
      ${codexSyncExtensions}/bin/codex-sync-extensions; then
      echo "[nix-darwin][codex] extension synchronization failed; inspect the command output above." >&2
    fi
  '';

  environment.systemPackages = [
    codebaseMemoryMcp
    codexSyncExtensions
    codexUpdateExtensions
  ];
}
