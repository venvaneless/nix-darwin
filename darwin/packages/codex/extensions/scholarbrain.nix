# CODEX: SCHOLARBRAIN
# =========================
# Install and update ScholarBrain for an Obsidian vault

{ lib, pkgs, ... }:

let
  installScholarBrain = pkgs.writeShellApplication {
    name = "install-scholarbrain";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.python3
    ];

    text = ''
      set -Eeuo pipefail


      # PATHS
      # =========================
      # ScholarBrain source shared by both Codex profiles
      source_root="/Users/ven/.config/codex/shared/scholarbrain"

      # Change this if the vault is stored somewhere else
      vault_root="/Users/ven/Library/Mobile Documents/iCloud~md~obsidian/Documents/My Hub"


      # SOURCE
      # =========================
      # Clone ScholarBrain or update the existing checkout
      if test -d "$source_root/.git"; then
        printf 'Updating ScholarBrain...\n'

        ${pkgs.git}/bin/git \
          -C "$source_root" \
          fetch \
          --prune \
          origin

        ${pkgs.git}/bin/git \
          -C "$source_root" \
          reset \
          --hard \
          origin/feat/deepseek-pubmed-arxiv
      else
        printf 'Downloading ScholarBrain...\n'

        rm -rf -- "$source_root"

        ${pkgs.git}/bin/git \
          clone \
          --branch feat/deepseek-pubmed-arxiv \
          --single-branch \
          https://github.com/SHzzzAyys/scholarbrain.git \
          "$source_root"
      fi


      # BUILD
      # =========================
      # Build ScholarBrain's official Codex CLI adapter
      cd -- "$source_root"

      ${pkgs.bash}/bin/bash \
        scripts/build.sh \
        --platform codex-cli


      # VAULT
      # =========================
      # Install the generated Codex files into the Obsidian vault
      if ! test -d "$vault_root"; then
        printf 'Obsidian vault does not exist: %s\n' "$vault_root" >&2
        exit 1
      fi

      ${pkgs.coreutils}/bin/cp \
        -R \
        dist/codex-cli/. \
        "$vault_root"/

      printf \
        'ScholarBrain installed into: %s\n' \
        "$vault_root"
    '';
  };
in
{
  environment.systemPackages = [
    installScholarBrain
  ];

  system.activationScripts.codexScholarBrain.text = lib.mkAfter ''
    echo "[nix-darwin][codex] Installing/updating ScholarBrain..."

    /usr/bin/sudo \
      -u ven \
      /usr/bin/env \
      HOME=/Users/ven \
      ${installScholarBrain}/bin/install-scholarbrain
  '';
}