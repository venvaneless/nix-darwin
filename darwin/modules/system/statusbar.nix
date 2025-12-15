# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/statusbar.nix
#
# STATUS BAR / CONTROL CENTER
# ============================================================
# Declarative-ish macOS status bar configuration.
#
# Apple limitations:
# - Control Center items are NOT exposed as real preferences
# - Ordering of 3rd-party apps is impossible to control
#
# This module:
# - Enables menu bar auto-hide
# - Hides all unwanted Apple status items
# - Keeps only language, battery, and clock
# - Applies changes reliably via activation script
# ============================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # STATUS BAR CONFIGURATION SCRIPT
  # ------------------------------------------------------------
  # Grouped by preference domain for readability.
  # ------------------------------------------------------------
  configureStatusBar = pkgs.writeShellScriptBin "configure-status-bar" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[statusbar] Applying macOS status bar configuration"

    # ==========================================================
    # NSGlobalDomain — MENU BAR BEHAVIOR
    # ==========================================================

    echo "[statusbar] Enabling menu bar auto-hide"
    defaults write NSGlobalDomain _HIHideMenuBar -bool true

    # ==========================================================
    # com.apple.controlcenter — STATUS ITEMS
    # ==========================================================

    echo "[statusbar] Configuring Control Center status items"

    # --- Hidden items
    defaults write com.apple.controlcenter "NSStatusItem Visible Siri"          -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible Spotlight"     -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible WiFi"          -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth"     -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible FocusModes"    -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible AirDrop"       -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible StageManager"  -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying"    -bool false

    # --- Explicitly kept items
    defaults write com.apple.controlcenter "NSStatusItem Visible InputMenu"     -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible Battery"       -bool true

    # ==========================================================
    # com.apple.menuextra.clock — CLOCK
    # ==========================================================

    echo "[statusbar] Configuring clock"

    defaults write com.apple.menuextra.clock ShowDate        -int 1
    defaults write com.apple.menuextra.clock ShowDayOfWeek  -bool true
    defaults write com.apple.menuextra.clock ShowSeconds    -bool false

    # ==========================================================
    # APPLY
    # ==========================================================

    echo "[statusbar] Restarting UI services"
    killall ControlCenter   2>/dev/null || true
    killall SystemUIServer  2>/dev/null || true

    echo "[statusbar] Status bar configuration complete"
  '';
in
{
  # ============================================================
  # ACTIVATION
  # ============================================================
  # nix-darwin–correct activation hook
  # ============================================================

  system.activationScripts.statusBar.text = ''
    echo "[nix-darwin] Configuring status bar"
    ${configureStatusBar}/bin/configure-status-bar
  '';
}
