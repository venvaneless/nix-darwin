# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/finder-options.nix
#
# FINDER OPTIONS
# ============================================================
# Finder defaults configured via nix-darwin.
# - Forces Finder to default to List view.
# - Adds basic visibility options
# - Provides placeholder blocks for more advanced view/column tuning.
# ============================================================
#
{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # FINDER CORE SETTINGS
  # View style and basic UI bars
  # ------------------------------------------------------------
  #
  system.defaults.finder = {

    # --- Show all hidden files
    AppleShowAllFiles = true;

    # --- Warn before changing file extensions
    FXEnableExtensionChangeWarning = false;

    # --- Default search scope (current folder)
    # -----------------------------------------
    # Valid values:
    #   "SCev" = This Mac
    #   "SCcf" = Current Folder
    #   "SCsp" = Previous Scope
    # -----------------------------------------
    FXDefaultSearchScope = "SCcf";

    # --- Default Finder location (“Home”)
    NewWindowTarget = "PfHm";
    
    # --- Alternative path:
    # NewWindowTargetPath = "/Users/ven/";

    # --- Default Finder view
    # -----------------------------------------
    # "icnv" (Icon)
    # "Nlsv" (List)
    # "clmv" (Column)
    # "glyv" (Gallery)
    # -----------------------------------------
    FXPreferredViewStyle = "Nlsv";

    # --- Folders on top
    _FXSortFoldersFirst = true;

    # Finder Sidebar
    SidebarWidth = 200;

    # --- Path bar at bottom
    ShowPathbar = true;

    # --- Show on Desktop
    # External HDDs
    ShowExternalHardDrivesOnDesktop = false;
    # Internal HDDs
    ShowHardDrivesOnDesktop         = false;
    # Servers
    ShowMountedServersOnDesktop     = false;
    # Removable media
    ShowRemovableMediaOnDesktop     = false;

    # --- Show Status bar at bottom
    ShowStatusBar = true;
  };


  # ----------------------------------------------------------------------
  # FINDER TRASH / CLEANUP SETTINGS
  # Extra Finder-related defaults not exposed under system.defaults.finder
  # -----------------------------------------------------------------------
  #
  # Using targets.darwin.defaults for non-standard preference keys.
  #
  targets.darwin.defaults."com.apple.finder".FXRemoveOldTrashItems = false;


  # ------------------------------------------------------------
  # FINDER VIEW PRESETS (PLACEHOLDER)
  # List view: font size, icon size, grouping and sorting
  # ------------------------------------------------------------
  #
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      # --- Basic template for list view tuning (commented for now) ---
      #
      "StandardViewSettings" = {
        "ListViewSettings" = {
           # 16px font for list view
           "textSize" = 16;
      
          # “Big” icon size; tweak as you like
          "iconSize" = 32;
      
           # Sort by column "name"
           "sortColumn" = "name";
           
           # Sort in ascending order
           "useRelativeDates" = 0;
           
            # -----------------------------------------------------------------------------
           # Placeholder for visible columns.
           # In practice this is an array of dicts and needs precise keys.
           # Columns you want: Name, Date Created, Date Modified, Size, iCloud status.
           # -----------------------------------------------------------------------------
           "columns" = 
      					{ identifier = "name"; },
        				{ identifier = "dateCreated"; },
      					{ identifier = "dateModified"; },
    						{ identifier = "size"; },
  							{ identifier = "iCloudStatus"; }
						 ];
        };
      };
    };
  };
}
