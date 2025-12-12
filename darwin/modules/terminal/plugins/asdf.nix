# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/asdf.nix
#
# DARWIN: ASDF VERSION MANAGER
# ====================================================================
# - asdf-vm is installed via Nix (binary only)
# - All plugin data lives in: ~/ven-dots/zsh/asdf
# - .tool-versions is stored inside the same directory
# - Shims are added to PATH
# - This preserves the classic "asdf install / asdf global" workflow
# ====================================================================

{ config, lib, pkgs, ... }:

let
  # ASDF DATA ROOT (your preferred location)
  asdfData = "${config.home.homeDirectory}/ven-dots/zsh/asdf";

in
{
  # ------------------------------------------------------------
  # ASDF PACKAGE
  # ------------------------------------------------------------
  # Install the asdf-vm binary from Nix. This gives us:
  # - asdf executable
  # - asdf.sh
  # - completions
  home.packages = [
    pkgs.asdf-vm
  ];


  # ------------------------------------------------------------
  # ASDF DIRECTORY LAYOUT
  # ------------------------------------------------------------
  # Create the full directory tree so asdf works like the classic ~/.asdf
  home.directories = [
    "ven-dots/zsh/asdf"
    "ven-dots/zsh/asdf/plugins"
    "ven-dots/zsh/asdf/installs"
    "ven-dots/zsh/asdf/shims"
    "ven-dots/zsh/asdf/tmp"
  ];


  # ------------------------------------------------------------
  # TOOL-VERSIONS FILE
  # ------------------------------------------------------------
  # Classic .tool-versions format, stored inside your ASDF root
  home.file."ven-dots/zsh/asdf/.tool-versions".text = ''
    nodejs latest
    python latest
  '';


  # ------------------------------------------------------------
  # ENVIRONMENT VARIABLES
  # ------------------------------------------------------------
  # Tell asdf to store everything inside ~/ven-dots/zsh/asdf
  home.sessionVariables = {
    ASDF_DATA_DIR = asdfData;
  };

  # Add shims to PATH so python/node/npm resolve correctly
  home.sessionPath = [
    "${asdfData}/shims"
  ];


  # ------------------------------------------------------------
  # ZSH INITIALIZATION
  # ------------------------------------------------------------
  # Load asdf from the Nix store, and use our ASDF_DATA_DIR
  programs.zsh.initContent = ''
    #### ASDF INITIALIZATION ####

    # Ensure correct ASDF data directory
    export ASDF_DATA_DIR="${asdfData}"

    # Load main asdf.sh
    if [ -f "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh" ]; then
      . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
    fi

    # Load completions (bash completions work under zsh)
    if [ -f "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash" ]; then
      . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash"
    fi
  '';
}
