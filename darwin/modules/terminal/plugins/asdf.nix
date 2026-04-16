# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/asdf.nix
#
# DARWIN: ASDF VERSION MANAGER
# ====================================================================
# - asdf-vm installed via Nix (binary only)
# - ASDF_DATA_DIR = ~/ven-dots/zsh/asdf
# - asdf is LOCAL-ONLY
# - mise handles all global runtimes
# ====================================================================

{ config, pkgs, lib, ... }:

let
  asdfData = "${config.home.homeDirectory}/.config/zsh/asdf";
in
{
  # ------------------------------------------------------------
  # ASDF PACKAGE
  # ------------------------------------------------------------
  home.packages = [
    pkgs.asdf-vm
  ];

  # ------------------------------------------------------------
  # ZSH ENVIRONMENT
  # ------------------------------------------------------------
  programs.zsh = {
    sessionVariables = {
      ASDF_DATA_DIR = asdfData;
    };

    initContent = lib.mkAfter ''
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
