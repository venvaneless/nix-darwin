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
      (pkgs.nerd-fonts.override {
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
  # For commercial / local fonts (Berkeley Mono, Operator Mono, etc.)
  # ------------------------------------------------------------
  #
  # Pattern:
  # 1. Create a small derivation that installs *.ttf/*.otf into
  #    $out/share/fonts/truetype or opentype.
  # 2. Call that derivation and add it to fonts.packages above.
  #
  # Example skeleton (keep in a separate file under ./pkgs/fonts if you want):
  #
  # let
  #   berkeley-mono = pkgs.callPackage
  #     ../../pkgs/fonts/berkeley-mono.nix
  #     { };
  # in {
  #   fonts.packages = fonts.packages ++ [ berkeley-mono ];
  # }
  #
}
