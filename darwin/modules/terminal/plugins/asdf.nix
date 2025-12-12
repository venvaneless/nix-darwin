# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/asdf.nix
#
# DARWIN: ASDF VERSION MANAGER
# ====================================================================
# - asdf-vm is installed via Nix (binary only)
# - ASDF_DATA_DIR = ~/ven-dots/zsh/asdf
# - .tool-versions stored inside ASDF_DATA_DIR
# - Shims added to PATH
# - Directories are created by asdf automatically
# ====================================================================

{ config, pkgs, ... }:

let
  asdfData = "${config.home.homeDirectory}/ven-dots/zsh/asdf";
in
{
  # ------------------------------------------------------------
  # ASDF PACKAGE
  # Install the asdf-vm binary from Nix. This gives us:
  # - asdf executable
  # - asdf.sh
  # - completions
  # ------------------------------------------------------------
  home.packages = [
    pkgs.asdf-vm
  ];

  # ------------------------------------------------------------
  # TOOL-VERSIONS FILE
  # Classic .tool-versions format, stored inside your ASDF root
  # ------------------------------------------------------------
  # home.file."ven-dots/zsh/asdf/.tool-versions".text = ''
  #  nodejs 25.0.0
  #  python 3.13.9
  # '';

  # ------------------------------------------------------------
  # ENVIRONMENT VARIABLES
  # Tell asdf to store everything inside ~/ven-dots/zsh/asdf
  # ------------------------------------------------------------
  programs.zsh.sessionVariables = {
    ASDF_DATA_DIR = asdfData;
  };

  programs.zsh.sessionPath = [
    "${asdfData}/shims"
  ];

  # ------------------------------------------------------------
  # ZSH INITIALIZATION
  # Binary paths to the asdf installation
  # ------------------------------------------------------------
  programs.zsh.initContent = ''
    #### ASDF INITIALIZATION ####
    export ASDF_DATA_DIR="${asdfData}"

    # Load main asdf.sh from Nix store
    if [ -f "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh" ]; then
      . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
    fi

    # Load completions (bash completions work in Zsh)
    if [ -f "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash" ]; then
      . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash"
    fi
  '';
}
