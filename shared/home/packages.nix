# shared/home/packages.nix
#
# =====================================================================
# HOME MANAGER: USER PACKAGE DECLARATIONS
#
# Installs portable user-scoped packages whose pinned Home Manager revision
# does not provide a dedicated program module. Program modules remain in
# their owning configuration area.
# =====================================================================

{ pkgs, ... }:

{
  # ------------------------------------------------------------
  # ------ TERMINAL TOOLS ------ #
  # Just runs repository-local recipes for Nix, Git, and Jujutsu workflows.
  # Glow renders Markdown in the terminal. Neither has a program module in
  # the pinned Home Manager revision, so this is their user-profile owner.

  home.packages = [
    pkgs.just
    pkgs.glow
  ];
}
