# CODEX: SIMPLE ENGLISH
# =========================
# Install and update the SimpleEnglish skill for Codex

{ lib, pkgs, ... }:

let
  installSimpleEnglish = pkgs.writeShellApplication {
    name = "install-codex-simple-english";

    runtimeInputs = [
      pkgs.nodejs
    ];

    text = ''
      set -Eeuo pipefail

      ${pkgs.nodejs}/bin/npx \
        --yes \
        skills \
        add AminBlg/SimpleEnglish \
        --agent codex \
        --global \
        --yes
    '';
  };
in
{
  environment.systemPackages = [
    installSimpleEnglish
  ];

  system.activationScripts.codexSimpleEnglish.text = lib.mkAfter ''
    echo "[nix-darwin][codex] Installing/updating SimpleEnglish..."

    /usr/bin/sudo \
      -u ven \
      /usr/bin/env \
      HOME=/Users/ven \
      CODEX_HOME=/Users/ven/.config/codex/shared \
      ${installSimpleEnglish}/bin/install-codex-simple-english
  '';
}