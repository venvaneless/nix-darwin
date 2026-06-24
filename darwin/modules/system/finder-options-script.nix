# /Users/ven/.config/nix/nix-config/darwin/modules/system/finder-options-script.nix
#
# =====================================================================
# FINDER OPTIONS
# 
# Declarative Finder configuration via nix-darwin.
#
# Covers:
# - Global Finder behavior
# - Default List view
# - Visibility and UI bars
# - Finder maintenance (one-time reset)
#
# IMPORTANT:
# Finder stores per-folder view state in .DS_Store files.
# These override defaults and must be reset imperatively.
# This reset is intentionally ONE-TIME only.
# =====================================================================

{ config, lib, pkgs, ... }:

# ---------------------------------------------------------------------------
let
  # ------ FINDER VIEW STATE ENFORCEMENT SCRIPT ------ #
  enforceFinderViews = pkgs.writeShellScriptBin "enforce-finder-views" ''
    #!/usr/bin/env bash
    set -euo pipefail

    LOG_PREFIX="[nix-darwin][finder]"
    STATE_FILE="$HOME/.finder-view-enforced"

    if [ -f "$STATE_FILE" ]; then
      echo "$LOG_PREFIX Finder views already enforced once, skipping"
      exit 0
    fi

    echo "$LOG_PREFIX Starting one-time Finder view enforcement"

    if pgrep Finder >/dev/null 2>&1; then
      echo "$LOG_PREFIX Stopping Finder"
      killall Finder || true
      sleep 1
    fi

    echo "$LOG_PREFIX Removing .DS_Store files"
    find "$HOME" -name ".DS_Store" -type f -print -delete || true

    FINDER_CACHE="$HOME/Library/Caches/com.apple.finder"
    if [ -d "$FINDER_CACHE" ]; then
      echo "$LOG_PREFIX Clearing Finder cache"
      rm -rf "$FINDER_CACHE"
    fi

    echo "$LOG_PREFIX Re-applying Finder defaults"
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder FXUseRelativeDates -bool false
    defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"

    echo "$LOG_PREFIX Restarting Finder"
    open -a Finder

    touch "$STATE_FILE"
    echo "$LOG_PREFIX Finder enforcement complete (one-time)"
  '';
  # ---------------------------------------------------------------------------

in
{
 # ********************************************************
  # ------ FINDER CORE SETTINGS ------ #
  system.defaults.finder = {
  # ********************************************************

 		# ***************************************************
    # ---- Files
    AppleShowAllFiles = true;
    FXRemoveOldTrashItems = false;
   	# ***************************************************

    # --- Windows management --- #
    NewWindowTarget = "Other";
    NewWindowTargetPath = "file:///Users/ven/iCloudDocs/Downloads/";
  
    # --- Views --- #
    FXPreferredViewStyle = "Nlsv";
    _FXSortFoldersFirst = true;
    
    
    # --- Search --- #
    FXDefaultSearchScope = "SCcf";
    
    # --- Extensions --- #
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false;

    # --- UI / Status bar --- #
    ShowPathbar  = true;
    ShowStatusBar = true;

    # ********************************************************
    # ------ DESKTOP ICONS ------ #
    CreateDesktop = true;
    ShowExternalHardDrivesOnDesktop = false;
    ShowHardDrivesOnDesktop         = false;
    ShowMountedServersOnDesktop     = false;
    ShowRemovableMediaOnDesktop     = false;
    _FXSortFoldersFirstOnDesktop    = true;
  };
  # ********************************************************

  # ********************************************************
  # ------ FINDER: RAW PREFERENCES ------ #
  # NOT EXPOSED BY NIX-DARWIN
  # ********************************************************
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      FXUseRelativeDates = false;
      FXArrangeGroupViewBy = "Name";
    };
  };

  system.activationScripts.finderViewReset.text = ''
    echo "[nix-darwin] Finder one-time view enforcement"
    ${enforceFinderViews}/bin/enforce-finder-views
  '';
}
