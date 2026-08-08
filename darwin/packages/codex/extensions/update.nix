# CODEX: EXTENSION UPDATER
# =========================
# Update all declaratively managed Codex extensions

{ config, lib, pkgs, ... }:

let
  updateCodexExtensions = pkgs.writeShellApplication {
    name = "update-codex-extensions";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gawk
      pkgs.git
      pkgs.jq
      pkgs.nix
      pkgs.nix-prefetch-github
    ];

    text = ''
      set -Eeuo pipefail


      # PATHS
      # =========================

      flake_root="/Users/ven/.config/nix/nix-config"


      # UPDATE
      # =========================

      cd "$flake_root"

      ${lib.concatStringsSep "\n\n" config.codex.extensionUpdaters}


      # REBUILD
      # =========================

      echo
      echo "Rebuilding nix-darwin..."

      exec /usr/bin/sudo \
        /run/current-system/sw/bin/darwin-rebuild \
        switch \
        --flake "$flake_root#macbook"
    '';
  };
in
{
  environment.systemPackages = [
    updateCodexExtensions
  ];
}