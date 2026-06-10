# /Users/ven/.config/nix/nix-config/darwin/modules/services/astrovim.nix
#
# =====================================================================
# ASTROVIM
# AstroNvim is an aesthetically pleasing and feature-rich
# Neovim configuration that focuses on extensibility and usability
# =====================================================================

{ lib, pkgs, inputs, ... }:

# Bash script wrapper
# ------------------------------------------------------------
let
  astroScript = pkgs.writeShellScriptBin "install-astrovim" ''
    #!/bin/bash
    set -euo pipefail

  # Config directories
  # ------------------------------------------------------------
    USER="ven"
    HOME_DIR="/Users/ven"
    CONFIG_DIR="$HOME_DIR/zsh/nvim/conf/"
    NVIM_DIR="$CONFIG_DIR/zsh/nvim/"

    echo ">>> [astrovim] Installing AstroNvim config"
    
  # Ensure directories exists
  # ------------------------------------------------------------
    mkdir -p "$CONFIG_DIR"
    rm -rf "$NVIM_DIR"
    rsync -a --delete "${inputs.astronvim}/" "$NVIM_DIR/"
    chown -R "$USER":staff "$NVIM_DIR"
    chmod -R u+rwX "$NVIM_DIR"

    echo ">>> [astrovim] AstroNvim linked successfully"
  '';
  
# Installing
# ------------------------------------------------------------
in
{
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> Running AstroNvim activation"
    ${astroScript}/bin/install-astrovim || echo "AstroNvim activation failed (ignored)"
  '';
}
