# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/fonts.nix
#
# SYSTEM FONTS
# ============================================================
# Font configuration for macOS via nix-darwin.
# - Installs patched Nerd Fonts for ligatures and powerline glyphs.
# - Uses fonts.packages (2025 API) to manage system fonts.
# - Provides placeholders for extra font packages and custom fonts.
# ============================================================
#
{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # INSTALLED FONTS
  # Nerd Fonts + additional monospaced and UI fonts
  # ------------------------------------------------------------
  #
  fonts = {

    # --------------------------------------------------------
    # PACKAGES
    # A list of font derivations to install system-wide.
    # Installed into /Library/Fonts/Nix Fonts (new macOS behavior).
    # --------------------------------------------------------
    packages = [

      # --- Nerd Fonts bundle with selected families ---
      # These are patched with ligatures, Powerline glyphs, etc.
      (pkgs.nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "Meslo"
        ];
      })

      # --- Additional nice monos / UIs (unpatched originals) ---
      pkgs.jetbrains-mono
      pkgs.fira-code

      # pkgs.monaspace
      # pkgs.inter
      # pkgs.noto-fonts
      # pkgs.noto-fonts-cjk-sans
      # pkgs.noto-fonts-emoji
    ];
  };


  # ------------------------------------------------------------
  # CUSTOM FONT DERIVATIONS (PLACEHOLDER)
  # For commercial / local fonts (Berkeley Mono
