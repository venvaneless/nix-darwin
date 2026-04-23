# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/nvim.nix
#
# USER: NEOVIM + ASTROVIM (REALISTIC, NO SYMLINKS)
# ============================================================

{ pkgs, lib, inputs, ... }:

let
  # ------------------------------------------------------------
  # PATHS
  # ------------------------------------------------------------
  nvimConfigRoot = "/Users/ven/.config/nvim";
  neovideRoot    = "/Users/ven/.config/neovide";

  # ------------------------------------------------------------
  # ASTROVIM INSTALLER (CONFIG ONLY, REAL PATH)
  # ------------------------------------------------------------
  astroInstall = pkgs.writeShellScriptBin "install-astrovim" ''
    #!/bin/bash
    set -euo pipefail

    echo ">>> [nvim] Installing AstroNvim config"

    mkdir -p "${nvimConfigRoot}"

    if [ ! -f "${nvimConfigRoot}/init.lua" ]; then
      ${pkgs.rsync}/bin/rsync -a --delete \
        "${inputs.astronvim}/" \
        "${nvimConfigRoot}/"
    else
      echo ">>> [nvim] AstroNvim already present, skipping"
    fi
  '';

  # ------------------------------------------------------------
  # NVIM WRAPPER (JUST ENSURES TOOLS EXIST)
  # ------------------------------------------------------------
  nvimWrapped = pkgs.writeShellScriptBin "nvim" ''
    #!/bin/bash
    set -e

    export PATH="${pkgs.git}/bin:${pkgs.curl}/bin:${pkgs.nodejs}/bin:$PATH"
    exec ${pkgs.neovim}/bin/nvim "$@"
  '';

  # ------------------------------------------------------------
  # NEOVIDE WRAPPER (ISOLATED)
  # ------------------------------------------------------------
  neovideWrapped = pkgs.writeShellScriptBin "neovide" ''
    #!/bin/bash
    set -e

    mkdir -p "${neovideRoot}"
    export HOME="${neovideRoot}"

    exec ${pkgs.neovide}/bin/neovide "$@"
  '';
in
{
  home.packages = [
    nvimWrapped
    neovideWrapped
    astroInstall
  ];

  home.activation.installAstroNvim =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${astroInstall}/bin/install-astrovim
    '';
}
