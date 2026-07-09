# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/development-pkgs.nix
#
# =====================================================================
# PACKAGES: DEVELOPMENT TOOLS
#
# Installs development and document-building tools:
# - Git helpers
# - Nix language tooling
# - Docker CLI
# - Node.js and Python
# - Pandoc and LaTeX/PDF tooling
# =====================================================================

{ pkgs, ... }:

let
  # ---- Custom TeX Live environment
  # Combines a medium TeX Live scheme with extra LaTeX packages needed by Pandoc/PDF workflows.
  myTex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium titlesec;
  };
in {
  # ------------------------------------------------------------
  # ------ DEVELOPMENT TOOLS ------ #
  #
  # Tools for source control, programming languages, Nix development,
  # containers, document conversion, and PDF generation.
  # ------------------------------------------------------------

  # ---- Development packages
  # Installs programming, Git, Nix, Docker, Python, Node, and document tooling.
  environment.systemPackages = with pkgs; [
    bitwarden-cli
    delta
    docker_29
    git-crypt
    git-filter-repo
    git-lfs
    home-manager
    lazygit
    nil
    nix-index
    nixd
    nodejs
    nssTools
    pandoc
    myTex
    python3
    python3Packages.pandas
    python3Packages.reportlab
  ];
}