# options/env-settings/default.nix
#
# =====================================================================
# OPTIONS: SHARED ENVIRONMENT SETTINGS
# =====================================================================
#
# Declares portable user-environment settings. Machine and shared policy
# files choose values only; this module selects the current platform and
# translates enabled settings into Home Manager-managed files.
# =====================================================================

{ config, lib, platforms, ... }:

let
  cfg = config.home.shared.envSettings.markdownlint;

  # ------------------------------------------------------------
  # ------ CURRENT PLATFORM SETTINGS ------ #
  # The knobs retain both platform paths. Only the path and toggle for
  # the Home Manager host currently being built are used.

  # An unsupported platform resolves to null, which means no symlink.
  createSymlink = platforms.valueForCurrentPlatform cfg.createSymlink == true;

  pathSymlink = platforms.valueForCurrentPlatform cfg.pathSymlink;

  # home.file targets are relative to Home Manager's home directory. The
  # knob remains an absolute path so paths.nix is its source of truth.
  homeFileTarget =
    if pathSymlink == null then
      null
    else
      lib.removePrefix "${config.home.homeDirectory}/" pathSymlink;
in
{
  options.home.shared.envSettings.markdownlint = {
    createSymlink = {
      darwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Create the managed Markdownlint configuration symlink on Darwin.";
      };

      linux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Create the managed Markdownlint configuration symlink on Linux.";
      };
    };

    pathSymlink = {
      darwin = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Absolute Darwin home path for the Markdownlint configuration symlink.";
      };

      linux = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Absolute Linux home path for the Markdownlint configuration symlink.";
      };
    };
  };

  config = {
    # Home Manager removes a link managed by an earlier generation when
    # its declaration disappears, so setting this platform toggle to false
    # removes the generated configuration link at the next activation.
    home.file = lib.mkIf createSymlink {
      ${homeFileTarget}.text = ''
        {
          "default": true,

          "MD001": false,
          "MD003": false,
          "MD009": false,
          "MD010": false,
          "MD012": false,
          "MD013": false,
          "MD022": false,
          "MD023": false,
          "MD024": false,
          "MD028": false,
          "MD030": false,
          "MD031": false,
          "MD032": false,
          "MD033": false,
          "MD034": false,
          "MD039": false,
          "MD041": false,
          "MD045": false,
          "MD047": false,
          "MD059": false
        }
      '';
    };

    assertions = [
      {
        assertion =
          !createSymlink
          || (
            pathSymlink != null
            && lib.hasPrefix "${config.home.homeDirectory}/" pathSymlink
            && homeFileTarget != ""
          );
        message = ''
          home.shared.envSettings.markdownlint.pathSymlink for the current platform
          must be a file below home.homeDirectory when createSymlink is true.
        '';
      }
    ];
  };
}
