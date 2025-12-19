# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/astrovim.nix
#
# SYSTEM: ASTROVIM
# ============================================================
# Declaratively installs AstroNvim config by symlinking
# the AstroNvim repo into ~/.config/nvim on every activation.
# Uses writeShellScriptBin to ensure reliable execution
# under nix-darwin activation.
# ============================================================

{ lib, pkgs, inputs, ... }:

let
  astroScript = pkgs.writeShellScriptBin "install-astrovim" ''
    #!/bin/bash
    set -euo pipefail

    USER="ven"
    HOME_DIR="/Users/ven"
    CONFIG_DIR="$HOME_DIR/.config"
    NVIM_DIR="$CONFIG_DIR/nvim"

    echo ">>> [astrovim] Installing AstroNvim config"

    mkdir -p "$CONFIG_DIR"
    rm -rf "$NVIM_DIR"
    rsync -a --delete "${inputs.astronvim}/" "$NVIM_DIR/"
    chown -R "$USER":staff "$NVIM_DIR"
    chmod -R u+rwX "$NVIM_DIR"

    echo ">>> [astrovim] AstroNvim linked successfully"
  '';
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running AstroNvim activation"
    ${astroScript}/bin/install-astrovim || echo "AstroNvim activation failed (ignored)"
  '';
}
