# options/settings/finder.nix
#
# =====================================================================
# OPTIONS: FINDER
#
# Readable Finder knobs translated into com.apple.finder preferences.
# null leaves a preference untouched.
# =====================================================================

{
  config,
  lib,
  platforms,
  ...
}:

let
  cfg = config.home.darwin.settings.finder;

  # ---- Finder codes
  newWindowTargetCodes = {
    "Computer" = "PfCm";
    "OS volume" = "PfVo";
    "Home" = "PfHm";
    "Desktop" = "PfDe";
    "Documents" = "PfDo";
    "Recents" = "PfAF";
    "iCloud Drive" = "PfID";
    "Other" = "PfLo";
  };

  viewStyleCodes = {
    "Icon" = "icnv";
    "List" = "Nlsv";
    "Column" = "clmv";
    "Gallery" = "Flwv";
  };

  searchScopeCodes = {
    "This Mac" = "SCev";
    "Current Folder" = "SCcf";
    "Previous Scope" = "SCsp";
  };

  # Names from Finder's Group By menu
  groupByValues = [
    "None"
    "Name"
    "Application"
    "Kind"
    "Date Last Opened"
    "Date Added"
    "Date Modified"
    "Date Created"
    "Size"
    "Tags"
  ];

  # ---- Boolean knobs: knob = [ key description ]
  windowBools = {
    showHidden = [ "AppleShowAllFiles" "Show hidden files and folders." ];
    removeOldTrash = [ "FXRemoveOldTrashItems" "Delete Trash items after 30 days." ];
    sortFoldersFirst = [ "_FXSortFoldersFirst" "Keep folders before files in windows." ];
    showExtensions = [ "AppleShowAllExtensions" "Show all filename extensions." ];
    extensionChangeWarning = [ "FXEnableExtensionChangeWarning" "Warn before changing an extension." ];
    pathBar = [ "ShowPathbar" "Show the path bar." ];
    statusBar = [ "ShowStatusBar" "Show the status bar." ];
    relativeDates = [ "FXUseRelativeDates" "Show relative dates such as Today." ];
  };

  desktopBools = {
    showIcons = [ "CreateDesktop" "Show items on the desktop." ];
    iconsExHDD = [ "ShowExternalHardDrivesOnDesktop" "Show external disks on the desktop." ];
    iconsHDD = [ "ShowHardDrivesOnDesktop" "Show internal disks on the desktop." ];
    iconsServers = [ "ShowMountedServersOnDesktop" "Show connected servers on the desktop." ];
    iconsRemovable = [ "ShowRemovableMediaOnDesktop" "Show removable media on the desktop." ];
    sortFoldersFirst = [ "_FXSortFoldersFirstOnDesktop" "Keep folders before files on the desktop." ];
  };

  # ---- Helpers
  boolOption = spec: lib.mkOption {
    type = lib.types.nullOr lib.types.bool;
    default = null;
    description = lib.elemAt spec 1;
  };

  enumOption = values: description: lib.mkOption {
    type = lib.types.nullOr (lib.types.enum values);
    default = null;
    inherit description;
  };

  boolDefaults = specs: values:
    lib.mapAttrs' (knob: spec: lib.nameValuePair (lib.head spec) values.${knob})
      (lib.filterAttrs (knob: _: values.${knob} != null) specs);

  setIf = value: attrs: lib.optionalAttrs (value != null) attrs;
in
{
  options.home.darwin.settings.finder =
    lib.mapAttrs (_: boolOption) windowBools
    // {
      newWindowTarget = enumOption (lib.attrNames newWindowTargetCodes)
        "Location new windows and tabs open; \"Other\" uses newWindowTargetPath.";

      newWindowTargetPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Folder opened when newWindowTarget is \"Other\".";
      };

      viewStyle = enumOption (lib.attrNames viewStyleCodes) "Default view for new windows.";
      searchScope = enumOption (lib.attrNames searchScopeCodes) "Where searches look by default.";
      arrangeGroupsView = enumOption groupByValues "How window items are grouped.";

      desktop = lib.mapAttrs (_: boolOption) desktopBools;
    };

  config = platforms.onlyOnDarwin {
    assertions = [
      {
        assertion = cfg.newWindowTarget != "Other" || cfg.newWindowTargetPath != null;
        message = "home.darwin.settings.finder.newWindowTargetPath must be set when newWindowTarget is \"Other\".";
      }
    ];

    targets.darwin.defaults."com.apple.finder" =
      boolDefaults windowBools cfg
      // boolDefaults desktopBools cfg.desktop
      // setIf cfg.newWindowTarget { NewWindowTarget = newWindowTargetCodes.${cfg.newWindowTarget}; }
      // setIf cfg.newWindowTargetPath { NewWindowTargetPath = "file://${cfg.newWindowTargetPath}/"; }
      // setIf cfg.viewStyle { FXPreferredViewStyle = viewStyleCodes.${cfg.viewStyle}; }
      // setIf cfg.searchScope { FXDefaultSearchScope = searchScopeCodes.${cfg.searchScope}; }
      // setIf cfg.arrangeGroupsView { FXArrangeGroupViewBy = cfg.arrangeGroupsView; };
  };
}
