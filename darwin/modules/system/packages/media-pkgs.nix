# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/media-pkgs.nix
#
# =====================================================================
# PACKAGES: MEDIA TOOLS
#
# Installs tools for media inspection and conversion:
# - Image manipulation
# - Video thumbnails
# - PDF rendering utilities
# - Media metadata tools
# - Visual/system display utilities
# =====================================================================

{ pkgs, ... }:

{
  # ------------------------------------------------------------
  # ------ MEDIA TOOLS ------ #
  #
  # Tools for images, PDFs, video thumbnails, media metadata,
  # and visual terminal/system display.
  # ------------------------------------------------------------

  # ---- Media packages
  # Installs image, video, PDF, media metadata, and visual utility tools.
  environment.systemPackages = with pkgs; [
    mediainfo
    poppler
    ytmdesktop
  ];
}