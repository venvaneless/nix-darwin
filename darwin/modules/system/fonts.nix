# /Users/ven/.config/nix/nix-config/darwin/modules/system/fonts.nix
#
# SYSTEM FONTS
# ============================================================
# Font configuration for macOS via nix-darwin.
# - Installs selected Nerd Fonts (patched variants).
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

      # --- Selected Nerd Fonts (patched) ---
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.meslo-lg

      # --- Optional original (unpatched) fonts ---
      # pkgs.jetbrains-mono
      # pkgs.fira-code

      # --- Extra UI / CJK fonts (commented placeholders) ---
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
  # let
  #   berkeley-mono = pkgs.callPackage ../../pkgs/fonts/berkeley-mono.nix { };
  # in {
  #   fonts.packages = fonts.packages ++ [ berkeley-mono ];
  # }
  #
}
