#
# ZSH: ASDF VERSION MANAGER (INSTALLED VIA NIX)
# ============================================================
# - Installs asdf-vm from Nix
# - Loads asdf.sh from the Nix store
# - Enables completions (bash completions work fine in Zsh)
# - Allows "asdf global nodejs 20.x", "asdf install python latest", etc.
# - Does NOT require ~/.asdf
# ============================================================

{ pkgs, ... }:

{
  # Install asdf via Nix
  home.packages = [
    pkgs.asdf-vm
  ];

  programs.zsh.initContent = ''
    #### ASDF INITIALIZATION ####

    # Load main ASDF environment
    if [ -f "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh" ]; then
      . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
    fi

    # Load ASDF completions (bash completions also work under Zsh)
    if [ -f "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash" ]; then
      . "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.bash"
    fi
  '';
}
