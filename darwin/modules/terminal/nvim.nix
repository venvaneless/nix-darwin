# darwin/modules/terminal/nvim.nix
#
# USER: NEOVIM + ASTROVIM
# ============================================================
# - Installs Neovim + Neovide
# - Uses a private XDG root at ven-dots/zsh/nvim
# - Installs AstroNvim declaratively
# - Wraps binaries so only Neovim is affected
# ============================================================

{ pkgs, lib, inputs, ... }:

let
  nvimRoot = "/Users/ven/ven-dots/zsh/nvim";

  # ------------------------------------------------------------
  # ASTROVIM INSTALLER
  # ------------------------------------------------------------
  astroInstall = pkgs.writeShellScriptBin "install-astrovim" ''
    #!/bin/bash
    set -euo pipefail

    echo ">>> [nvim] Ensuring Neovim directory layout"

    mkdir -p \
      "${nvimRoot}/conf" \
      "${nvimRoot}/data" \
      "${nvimRoot}/cache"

    if [ ! -f "${nvimRoot}/conf/init.lua" ]; then
      echo ">>> [nvim] Installing AstroNvim config"
      rsync -a "${inputs.astronvim}/" "${nvimRoot}/conf/"
    else
      echo ">>> [nvim] AstroNvim already present, skipping"
    fi
  '';

  # ------------------------------------------------------------
  # NVIM WRAPPER
  # ------------------------------------------------------------
  nvimWrapped = pkgs.writeShellScriptBin "nvim" ''
    #!/bin/bash
    export XDG_CONFIG_HOME="${nvimRoot}/conf"
    export XDG_DATA_HOME="${nvimRoot}/data"
    export XDG_CACHE_HOME="${nvimRoot}/cache"
    exec ${pkgs.neovim}/bin/nvim "$@"
  '';

  # ------------------------------------------------------------
  # NEOVIDE WRAPPER
  # ------------------------------------------------------------
  neovideWrapped = pkgs.writeShellScriptBin "neovide" ''
    #!/bin/bash
    export XDG_CONFIG_HOME="${nvimRoot}/conf"
    export XDG_DATA_HOME="${nvimRoot}/data"
    export XDG_CACHE_HOME="${nvimRoot}/cache"
    exec ${pkgs.neovide}/bin/neovide "$@"
  '';
in
{
  # ------------------------------------------------------------
  # PACKAGES
  # ------------------------------------------------------------
  home.packages = [
    nvimWrapped
    neovideWrapped
    astroInstall
  ];

  # ------------------------------------------------------------
  # INSTALL ASTROVIM ON ACTIVATION
  # ------------------------------------------------------------
  home.activation.installAstroNvim =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${astroInstall}/bin/install-astrovim
    '';
}
