# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/asdf.nix
#
# DARWIN: ASDF VERSION MANAGER
# ====================================================================
# - asdf-vm installed via Nix (binary only)
# - ASDF_DATA_DIR = ~/ven-dots/zsh/asdf
# - Real .tool-versions lives in ven-dots and is symlinked to $HOME
# - Shims added to PATH via home.sessionPath
# ====================================================================

{ config, pkgs, lib, ... }:

let
  asdfData = "${config.home.homeDirectory}/ven-dots/zsh/asdf";
in
{
  # ------------------------------------------------------------
  # ASDF PACKAGE
  # ------------------------------------------------------------
  home.packages = [
    pkgs.asdf-vm
  ];

  # ------------------------------------------------------------
  # GLOBAL TOOL-VERSIONS (OUT-OF-STORE SYMLINK)
  # NOTE:
  # - In nix-darwin + integrated Home Manager, the symlink helper is:
  #   config.lib.file.mkOutOfStoreSymlink
  # - nixpkgs lib (lib.*) does NOT provide lib.file.*
  # ------------------------------------------------------------
  home.file.".tool-versions".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/ven-dots/zsh/asdf/.tool-versions";

  # ------------------------------------------------------------
  # ZSH ENVIRONMENT
  # ------------------------------------------------------------
  programs.zsh = {
    sessionVariables = {
      ASDF_DATA_DIR = asdfData;
    };

    initContent = ''
      #### ASDF INITIALIZATION ####

      export ASDF_DATA_DIR="${asdfData}"

      # Load asdf from Nix store
      if [ -f "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh" ]; then
        . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
      fi

      # Load completions (bash completions work in Zsh)
      if [ -f "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash" ]; then
        . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash"
      fi
    '';
  };

  # ------------------------------------------------------------
  # PATH EXTENSION
  # ------------------------------------------------------------
  home.sessionPath = [
    "${asdfData}/shims"
  ];
}
