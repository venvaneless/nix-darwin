# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/nvim.nix
#
# USER: NEOVIM + ASTROVIM
# ============================================================
# - Installs Neovim + Neovide
# - Uses a private Neovim root at:
#     /Users/ven/ven-dots/zsh/nvim
#   with:
#     conf/  data/  cache/
# - Installs AstroNvim declaratively (config only)
# - Fully isolates Neovide state at:
#     /Users/ven/ven-dots/user-data/apps/neovide
# ============================================================

{ pkgs, lib, inputs, ... }:

let
  # ------------------------------------------------------------
  # PATHS
  # ------------------------------------------------------------
  nvimRoot    = "/Users/ven/ven-dots/zsh/nvim";
  neovideRoot = "/Users/ven/ven-dots/user-data/apps/neovide";

  # ------------------------------------------------------------
  # ASTROVIM INSTALLER (CONFIG ONLY)
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
      ${pkgs.rsync}/bin/rsync -a --delete "${inputs.astronvim}/" "${nvimRoot}/conf/"
    else
      echo ">>> [nvim] AstroNvim already present, skipping"
    fi
  '';

  # ------------------------------------------------------------
  # NVIM WRAPPER (NO XDG, FULLY CONTROLLED ROOT)
  # ------------------------------------------------------------
  nvimWrapped = pkgs.writeShellScriptBin "nvim" ''
    #!/bin/bash
    set -e

    # Neovim root (conf/, data/, cache/)
    export HOME="${nvimRoot}"
    export NVIM_APPNAME="nvim"

    # Required for AstroNvim / Lazy.nvim bootstrap
    export PATH="${pkgs.git}/bin:${pkgs.curl}/bin:${pkgs.nodejs}/bin:$PATH"

    exec ${pkgs.neovim}/bin/nvim "$@"
  '';

  # ------------------------------------------------------------
  # NEOVIDE WRAPPER (STRICTLY NEOVIDE STATE)
  # ------------------------------------------------------------
  neovideWrapped = pkgs.writeShellScriptBin "neovide" ''
    #!/bin/bash
    set -e

    mkdir -p "${neovideRoot}"

    # Neovide gets its own isolated HOME
    export HOME="${neovideRoot}"

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
