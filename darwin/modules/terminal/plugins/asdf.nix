# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/asdf.nix
#
# DARWIN: ASDF VERSION MANAGER
# ====================================================================
# - asdf-vm is installed via Nix (binary only)
# - ASDF_DATA_DIR = ~/ven-dots/zsh/asdf
# - .tool-versions stored manually or via Nix
# - Shims added to PATH via home.sessionPath
# ====================================================================

{ config, pkgs, ... }:

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
  # OPTIONAL: TOOL-VERSIONS FILE
  # (Commented out so you can maintain manually)
  # ------------------------------------------------------------
  # home.file."ven-dots/zsh/asdf/.tool-versions".text = ''
  #   nodejs 25.0.0
  #   python 3.13.9
  # '';

  # ------------------------------------------------------------
  # ENVIRONMENT VARIABLES
  # MUST be inside programs.zsh = { sessionVariables = { ... }; }
  # ------------------------------------------------------------
  programs.zsh = {
    sessionVariables = {
      ASDF_DATA_DIR = asdfData;
      ASDF_CONFIG_FILE = "${asdfData}/.tool-versions";
    };

    initContent = ''
      #### ASDF INITIALIZATION ####
      export ASDF_DATA_DIR="${asdfData}"
      export ASDF_CONFIG_FILE="${asdfData}/.tool-versions"

      # Load main asdf.sh from Nix store
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
  # This MUST be under home.sessionPath, never under programs.zsh
  # ------------------------------------------------------------
  home.sessionPath = [
    "${asdfData}/shims"
  ];
}
