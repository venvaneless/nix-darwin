# CODEX: EXTENSION UPDATER
# =========================
# Update all independently managed Codex extensions

{ pkgs, ... }:

let
  updateCodexExtensions = pkgs.writeShellApplication {
    name = "update-codex-extensions";

    runtimeInputs = [
      pkgs.coreutils
    ];

    text = ''
      set -Eeuo pipefail


      # CAVEMAN
      # =========================
      printf '\nUpdating Caveman...\n'

      /run/current-system/sw/bin/install-codex-caveman


      # SIMPLE ENGLISH
      # =========================
      printf '\nUpdating SimpleEnglish...\n'

      /run/current-system/sw/bin/install-codex-simple-english


      # CODEBASE MEMORY MCP
      # =========================
      printf '\nUpdating Codebase Memory MCP...\n'

      /run/current-system/sw/bin/install-codebase-memory-mcp

      /run/current-system/sw/bin/sync-codebase-memory-mcp


      # SCHOLARBRAIN
      # =========================
      printf '\nUpdating ScholarBrain...\n'

      /run/current-system/sw/bin/install-scholarbrain


      # FINISHED
      # =========================
      printf '\nCodex extensions updated successfully.\n'
    '';
  };
in
{
  environment.systemPackages = [
    updateCodexExtensions
  ];
}