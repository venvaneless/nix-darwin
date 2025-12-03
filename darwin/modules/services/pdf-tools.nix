# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/pdf-tools.nix
#
# PDF + Konvertierungswerkzeuge
# ===========================================
# Stellt vollständiges LaTeX bereit (scheme-medium + titlesec)
# und Tools wie Pandoc, Python + ReportLab für CSV/Markdown → PDF.
# ===========================================

{ config, pkgs, ... }:

let
  myTex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium titlesec;
  };
in {
  environment.systemPackages = with pkgs; [
    pandoc
    myTex
    python3
    python3Packages.pandas
    python3Packages.reportlab
  ];
}
