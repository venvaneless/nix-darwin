# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/fonts.nix
#
# SYSTEM FONTS
# ============================================================
# Font configuration for macOS via nix-darwin.
# - Installs patched Nerd Fonts for ligatures and powerline glyphs.
# - Exposes fonts under ~/Library/Fonts via fonts.fontDir.enable.
# - Provides placeholders for extra font packages and custom fonts.
# ============================================================
#
{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # CORE FONT DIRECTORY
  # Link all configured fonts into ~/Library/Fonts
  # ------------------------------------------------------------
  #
  # fonts.fontDir.enable creates a directory of symlinked fonts under
  # /run/current-system/sw/share/X11/fonts and exposes them to apps. :contentReference[oaicite:7]{index=7}
  #
  fonts = {

    # --------------------------------------------------------
    # INSTALLED FONTS
    # Nerd Fonts + any extra families you want
    # --------------------------------------------------------
    #
    # On Darwin, fonts.fonts works like fonts.packages on NixOS:
    # list out font packages (including nerdfonts overrides). :contentReference[oaicite:8]{index=8}
    #
    packages = [
      # --- Nerd Fonts bundle with selected families ---
      (pkgs.nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "Meslo"
        ];
      })

      # --- Additional nice monos / UIs (commented placeholders) ---
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
  # 2. Call that derivation and add it to fonts.fonts above. :contentReference[oaicite:9]{index=9}
  #
  # Example skeleton (keep in a separate file under ./pkgs if you want):
  #
  # let
  #   berkeley-mono = pkgs.callPackage
  #     ../../pkgs/fonts/berkeley-mono.nix
  #     { };
  # in {
  #   fonts.fonts = fonts.fonts ++ [ berkeley-mono ];
  # }
  #
  # Then use the font name in:
  # - WezTerm / iTerm / Zed / VS Code / etc.
  # - Your Starship config for the prompt.
}
