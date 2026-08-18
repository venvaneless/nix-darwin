# CODEX: EXTENSIONS
# =========================
# Load Codex extensions and provide one command to update all of them

{ pkgs, ... }:

let
  # CODEX: UPDATE ALL EXTENSIONS
  # =========================
  # Discover every extension updater and rebuild nix-darwin once afterward

  updateCodexExtensions = pkgs.writeShellApplication {
    name = "update-codex-extensions";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];

    text = ''
      set -Eeuo pipefail


      # PATHS
      # =========================

      system_bin="/run/current-system/sw/bin"
      flake_root="/Users/ven/.config/nix/nix-config"


      # DISCOVER
      # =========================
      # Each extension exposes its own internal update-codex-* updater

      updaters="$(
        find "$system_bin" \
          -maxdepth 1 \
          -type l \
          -name 'update-codex-*' \
          ! -name 'update-codex-extensions' \
          -print \
          | sort
      )"


      # UPDATE
      # =========================

      if test -z "$updaters"; then
        printf 'No Codex extension updaters were found.\n'
        exit 0
      fi

      while IFS= read -r updater; do
        test -n "$updater" || continue

        name="$(basename "$updater")"

        printf '\n'
        printf 'Updating: %s\n' "$name"
        printf '%s\n' '----------------------------------------'

        "$updater"
      done <<< "$updaters"


      # REBUILD
      # =========================
      # Rebuild once after every extension has been updated

      printf '\n'
      printf 'Rebuilding nix-darwin...\n'

      exec /usr/bin/sudo \
        /run/current-system/sw/bin/darwin-rebuild \
        switch \
        --flake "$flake_root#macbook"
    '';
  };
in
{
  imports = [
    ./shared.nix

    ./caveman.nix
    ./claude-mem.nix
    ./simple-english.nix
    ./codebase-memory-mcp.nix

    # ScholarBrain is shared by the api and chatgpt Codex profiles.
    ./scholarbrain.nix
  ];

  environment.systemPackages = [
    updateCodexExtensions
  ];
}
