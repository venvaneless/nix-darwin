# /Users/ven/.config/nix/nix-config/darwin/modules/apps/keyboardSwitcher.nix
#
# =====================================================================
# KEYBOARD SWITCHER
# 
# Utility used by Raycast to switch keyboard layouts
# Homebrew formula from lutzifer/homebrew-tap
# =====================================================================

{ ... }:

let
# Package metadata
# ------------------------------------------------------------
  packageName = "keyboardSwitcher";
  tapName     = "lutzifer/homebrew-tap";
in
{
  # Homebrew tap
  # ------------------------------------------------------------
    homebrew.taps = [
      "lutzifer/homebrew-tap"
    ];

  # Homebrew formula
  # ------------------------------------------------------------
  homebrew.brews = [
    "lutzifer/homebrew-tap/keyboardSwitcher"
  ];
}