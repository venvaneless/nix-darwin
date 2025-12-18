# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/statusbar.nix
#
# STATUS BAR / CONTROL CENTER
# ============================================================
# Declarative-ish macOS status bar configuration.
#
# Goals:
# - Auto-hide menu bar
# - Show ONLY:
#   - Control Center
#   - Battery
#   - Input / language menu
#   - Third-party apps (Raycast, etc.)
#
# Apple limitations:
# - Ordering is NOT controllable
# - Control Center contents are mostly not scriptable
# ============================================================

{ lib, pkgs, ... }:

let
  configureStatusBar = pkgs.writeShellScriptBin "configure-status-bar" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[statusbar] Applying macOS status bar configuration"

    # ==========================================================
    # MENU BAR BEHAVIOR
    # ==========================================================

    echo "[statusbar] Enabling menu bar auto-hide"
    defaults write NSGlobalDomain _HIHideMenuBar -bool true

    # ==========================================================
    # STATUS ITEMS (MENU BAR)
    # ==========================================================

    echo "[statusbar] Configuring visible status items"

    # --- Hide everything noisy
    defaults write com.apple.controlcenter "NSStatusItem Visible WiFi"         -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth"   -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible AirDrop"     -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible FocusModes"  -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying"  -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible Siri"        -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible Spotlight"   -bool false
    defaults write com.apple.controlcenter "NSStatusItem Visible StageManager" -bool false

    # --- Explicitly keep essentials
    defaults write com.apple.controlcenter "NSStatusItem Visible ControlCenter" -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible Battery"       -bool true
    defaults write com.apple.controlcenter "NSStatusItem Visible InputMenu"     -bool true

    # ==========================================================
    # CLOCK
    # ==========================================================

    echo "[statusbar] Configuring clock"

    defaults write com.apple.menuextra.clock ShowDate       -int 1
    defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
    defaults write com.apple.menuextra.clock ShowSeconds   -bool false

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
  system.activationScripts.statusBar.text = ''
    echo "[nix-darwin] Configuring status bar"
    ${configureStatusBar}/bin/configure-status-bar
  '';
}
