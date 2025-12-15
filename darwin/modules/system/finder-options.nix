# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/finder-options.nix
#
# FINDER OPTIONS
# ============================================================
# Declarative Finder configuration via nix-darwin.
#
# Covers:
# - Global Finder behavior
# - Default List view
# - Visibility and UI bars
# - List view presets (best-effort, Apple-limited)
# - Explicit enforcement to override per-folder Finder state
#
# IMPORTANT:
# Finder stores per-folder view state in .DS_Store files.
# These override defaults and must be reset imperatively.
# ============================================================

{ config, lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # FINDER VIEW STATE ENFORCEMENT SCRIPT
  # ------------------------------------------------------------
  # Clears per-folder Finder view state so defaults actually apply.
  #
  # Apple overrides defaults using:
  # - .DS_Store files
  # - FXInfoDictionary entries
  #
  # This script resets that state safely.
  # ------------------------------------------------------------
  enforceFinderViews = pkgs.writeShellScriptBin "enforce-finder-views" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[finder] Resetting Finder view state"

    # Remove per-folder Finder overrides
    find "$HOME" -name .DS_Store -type f -delete || true

    # Clear Finder internal view dictionaries
    defaults delete com.apple.finder FXInfoDictionary 2>/dev/null || true
    defaults delete com.apple.finder FXInfoDictionaryExpanded 2>/dev/null || true

    # Restart Finder to apply defaults
    killall Finder || true

    echo "[finder] Finder view reset complete"
  '';
in
{
  # ============================================================
  # FINDER CORE SETTINGS
  # ============================================================
  system.defaults.finder = {

    # ----------------------------------------------------------
    # VISIBILITY & SAFETY
    # ----------------------------------------------------------

    # Show hidden files
    AppleShowAllFiles = true;

    # Warn before changing file extensions
    FXEnableExtensionChangeWarning = false;

    # ----------------------------------------------------------
    # SEARCH & WINDOW BEHAVIOR
    # ----------------------------------------------------------

    # Default search scope: current folder
    # SCev = This Mac
    # SCcf = Current Folder
    # SCsp = Previous Scope
    FXDefaultSearchScope = "SCcf";

    # New Finder windows open at Home
    NewWindowTarget = "Home";

    # ----------------------------------------------------------
    # VIEW STYLE
    # ----------------------------------------------------------

    # Default view style:
    # icnv = Icon
    # Nlsv = List
    # clmv = Column
    # glyv = Gallery
    FXPreferredViewStyle = "Nlsv";

    # Keep folders above files
    _FXSortFoldersFirst = true;

    # ----------------------------------------------------------
    # UI BARS
    # ----------------------------------------------------------

    # Show path bar
    ShowPathbar = true;

    # Show status bar
    ShowStatusBar = true;

    # ----------------------------------------------------------
    # DESKTOP ICONS
    # ----------------------------------------------------------

    ShowExternalHardDrivesOnDesktop = false;
    ShowHardDrivesOnDesktop         = false;
    ShowMountedServersOnDesktop     = false;
    ShowRemovableMediaOnDesktop     = false;
  };

  # ============================================================
  # FINDER MAINTENANCE
  # ============================================================

  # Do not auto-remove trash items
  system.defaults.finder.FXRemoveOldTrashItems = false;

  # ============================================================
  # FINDER LIST VIEW PRESETS (BEST-EFFORT)
  # ============================================================
  # NOTE:
  # These apply ONLY as defaults.
  # Existing folders override them via .DS_Store.
  # Enforcement is handled below.
  # ============================================================

  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      "StandardViewSettings" = {
        "ListViewSettings" = {

          # Font size for list rows
          "textSize" = 16;

          # Icon size in list view
          "iconSize" = 32;

          # Sort by name
          "sortColumn" = "name";

          # Use absolute dates
          "useRelativeDates" = 0;

          # Visible columns (best-effort)
          "columns" = [
            { identifier = "name"; }
            { identifier = "dateCreated"; }
            { identifier = "dateModified"; }
            { identifier = "size"; }
            { identifier = "iCloudStatus"; }
          ];
        };
      };
    };
  };

  # ============================================================
  # FINDER VIEW STATE ENFORCEMENT (IMPERATIVE, DECLARATIVE-TRIGGERED)
  # ============================================================

  system.activationScripts.finderViewReset.text = ''
    echo "[nix-darwin] Enforcing Finder List view defaults"
    ${enforceFinderViews}/bin/enforce-finder-views
  '';
}
