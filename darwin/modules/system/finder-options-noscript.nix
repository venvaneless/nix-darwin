# /Users/ven/.config/nix/nix-config/darwin/modules/system/finder-options-noscript.nix
#
# FINDER OPTIONS
# ============================================================
# Declarative Finder configuration via nix-darwin.
#
# Covers:
# - Global Finder behavior
# - Default List view
# - Visibility and UI bars
#
# Finder per-folder view state (.DS_Store) is NOT touched here.
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ============================================================
  # FINDER CORE SETTINGS
  # ============================================================
  system.defaults.finder = {

    # ----------------------------------------------------------
    # FILES
    # ----------------------------------------------------------
    AppleShowAllFiles = true;
    FXRemoveOldTrashItems = false;
    
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

    # ----------------------------------------------------------
    # DESKTOP ICONS
    # ----------------------------------------------------------
    CreateDesktop = true;
    ShowExternalHardDrivesOnDesktop = false;
    ShowHardDrivesOnDesktop         = false;
    ShowMountedServersOnDesktop     = false;
    ShowRemovableMediaOnDesktop     = false;
    _FXSortFoldersFirstOnDesktop    = true;
  };

  # ============================================================
  # FINDER: RAW PREFERENCES (NOT EXPOSED BY NIX-DARWIN)
  # ============================================================
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      FXUseRelativeDates = false;
      FXArrangeGroupViewBy = "Name";
    };
  };
}
