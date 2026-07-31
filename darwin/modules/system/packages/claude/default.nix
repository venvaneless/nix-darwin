# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/claude/default.nix
#
# =====================================================================
# PACKAGE: CLAUDE
#
# Manages:
# - Claude Code CLI
# - Claude Desktop for macOS
# - Claude Code environment variables
# - Optional Claude Desktop application link
#
# Disabling a package removes it from the system generation.
# Disabling the application link removes only the link created by this
# module and never deletes unrelated applications or symbolic links.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ------------------------------------------------------------
  # ------ CLAUDE SETTINGS ------ #
  #
  # Main package and feature toggles.
  #
  # enable:
  #   Controls all Claude packages and configuration.
  #
  # code.enable:
  #   Controls Claude Code CLI.
  #
  # desktop.enable:
  #   Controls Claude Desktop.
  #
  # desktop.link.enable:
  #   Controls the optional application symlink.
  # ------------------------------------------------------------

  claudeSettings = {
    enable = true;

    code = {
      enable = true;
    };

    desktop = {
      enable = true;

      link = {
        enable = true;
      };
    };
  };

  # ------------------------------------------------------------
  # ------ MODULE CONFIGURATION ------ #
  # ------------------------------------------------------------

  cfg = config.ven.packages.claude;

  # ------------------------------------------------------------
  # ------ PLATFORM DETECTION ------ #
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # ------------------------------------------------------------
  # ------ CLAUDE DESKTOP RELEASE ------ #
  #
  # Generated and updated by update-claude-desktop.sh.
  # ------------------------------------------------------------

  claudeDesktopRelease =
    import ./claude-desktop-release.nix;

  # ------------------------------------------------------------
  # ------ CLAUDE DESKTOP PACKAGE ------ #
  #
  # Packages Anthropic's official macOS application archive.
  #
  # Update these values when Anthropic publishes a new release:
  # - version
  # - releaseId
  # - sourceHash
  #
  # The download URL may also be replaced completely through the
  # downloadUrl option.
  # ------------------------------------------------------------

  claudeDesktopPackage =
    pkgs.callPackage ./claude-desktop.nix {
      inherit
        (cfg.desktop.package)
        version
        releaseId
        sourceHash
        downloadUrl
        applicationName
        ;
    };

  # ------------------------------------------------------------
  # ------ CLAUDE ENVIRONMENT ------ #
  # ------------------------------------------------------------

  claudeEnvironment =
    {
      CLAUDE_CONFIG_DIR =
        cfg.code.configDirectory;

      CLAUDE_MEM_DATA_DIR =
        cfg.code.memoryDataDirectory;

      CLAUDE_CODE_PATH =
        cfg.code.executablePath;

      NPM_CONFIG_USERCONFIG =
        cfg.npm.userConfigPath;

      NPM_CONFIG_CACHE =
        cfg.npm.cacheDirectory;
    }
    // lib.optionalAttrs cfg.code.disableAutoUpdater {
      DISABLE_AUTOUPDATER = "1";
    };

  # ------------------------------------------------------------
  # ------ ENABLED PACKAGES ------ #
  # ------------------------------------------------------------

  enabledClaudePackages =
    lib.optionals
      (cfg.enable && cfg.code.enable)
      [
        pkgs.claude-code
      ]
    ++ lib.optionals
      (
        cfg.enable
        && cfg.desktop.enable
        && isDarwin
      )
      [
        claudeDesktopPackage
        claudeDesktopPackage.updateScriptPackage
      ];

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINK PATHS ------ #
  # ------------------------------------------------------------

  claudeDesktopSourcePath =
    "${cfg.desktop.link.sourceDirectory}/${cfg.desktop.package.applicationName}";

  claudeDesktopTargetPath =
    "${cfg.desktop.link.targetDirectory}/${cfg.desktop.package.applicationName}";

  claudeDesktopLinkShouldExist =
    cfg.enable
    && cfg.desktop.enable
    && cfg.desktop.link.enable
    && isDarwin;

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINK MANAGER ------ #
  #
  # Creates or removes only the symbolic link owned by this
  # module.
  #
  # It refuses to replace:
  # - Existing applications
  # - Existing files
  # - Unrelated symbolic links
  # ------------------------------------------------------------

  manageClaudeDesktopLink =
    pkgs.writeShellScriptBin "manage-claude-desktop-link" ''
      set -euo pipefail

      display_name=${lib.escapeShellArg cfg.desktop.displayName}
      source_path=${lib.escapeShellArg claudeDesktopSourcePath}
      target_path=${lib.escapeShellArg claudeDesktopTargetPath}
      should_exist=${lib.escapeShellArg (
        if claudeDesktopLinkShouldExist then
          "true"
        else
          "false"
      )}

      target_directory="$(
        ${pkgs.coreutils}/bin/dirname \
          -- \
          "$target_path"
      )"

      echo "[$display_name] Application link management started."
      echo "[$display_name] Source: $source_path"
      echo "[$display_name] Target: $target_path"
      echo "[$display_name] Requested state: $should_exist"

      # Validate the source path.
      # ----------------------------------------------------------

      case "$source_path" in
        "/Applications/Nix Apps/"*.app)
          ;;
        *)
          echo "[$display_name] ERROR: Unsupported source path." >&2
          echo "[$display_name] Refusing source: $source_path" >&2
          exit 1
          ;;
      esac

      # Validate the target path.
      # ----------------------------------------------------------

      case "$target_path" in
        /Applications/*.app)
          ;;
        *)
          echo "[$display_name] ERROR: Unsupported target path." >&2
          echo "[$display_name] Refusing target: $target_path" >&2
          exit 1
          ;;
      esac

      # Create or verify the managed link.
      # ----------------------------------------------------------

      if [ "$should_exist" = "true" ]; then
        if [ ! -d "$source_path" ]; then
          echo "[$display_name] ERROR: Nix-managed application was not found." >&2
          echo "[$display_name] Expected: $source_path" >&2
          exit 1
        fi

        if [ ! -d "$target_directory" ]; then
          echo "[$display_name] Creating target directory."

          ${pkgs.coreutils}/bin/mkdir \
            -p \
            -- \
            "$target_directory"
        fi

        if [ ! -d "$target_directory" ]; then
          echo "[$display_name] ERROR: Target directory was not created." >&2
          exit 1
        fi

        if [ -L "$target_path" ]; then
          existing_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          if [ "$existing_target" = "$source_path" ]; then
            echo "[$display_name] SUCCESS: Application link is already correct."
            exit 0
          fi

          echo "[$display_name] ERROR: An unrelated symbolic link exists." >&2
          echo "[$display_name] Existing target: $existing_target" >&2
          exit 1
        fi

        if [ -e "$target_path" ]; then
          echo "[$display_name] ERROR: The target path is occupied." >&2
          echo "[$display_name] Existing item: $target_path" >&2
          echo "[$display_name] Refusing to replace it." >&2
          exit 1
        fi

        echo "[$display_name] Creating application link."

        ${pkgs.coreutils}/bin/ln \
          -s \
          -- \
          "$source_path" \
          "$target_path"

        if [ ! -L "$target_path" ]; then
          echo "[$display_name] ERROR: Application link was not created." >&2
          exit 1
        fi

        existing_target="$(
          ${pkgs.coreutils}/bin/readlink \
            -- \
            "$target_path"
        )"

        if [ "$existing_target" != "$source_path" ]; then
          echo "[$display_name] ERROR: Application link has the wrong target." >&2
          echo "[$display_name] Actual target: $existing_target" >&2
          exit 1
        fi

        echo "[$display_name] SUCCESS: Application link created and verified."
        exit 0
      fi

      # Remove only the link owned by this module.
      # ----------------------------------------------------------

      if [ -L "$target_path" ]; then
        existing_target="$(
          ${pkgs.coreutils}/bin/readlink \
            -- \
            "$target_path"
        )"

        if [ "$existing_target" = "$source_path" ]; then
          echo "[$display_name] Removing managed application link."

          ${pkgs.coreutils}/bin/rm \
            -f \
            -- \
            "$target_path"

          if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            echo "[$display_name] ERROR: Managed link was not removed." >&2
            exit 1
          fi

          echo "[$display_name] SUCCESS: Managed application link removed."
          exit 0
        fi

        echo "[$display_name] Existing link is not owned by this module."
        echo "[$display_name] Preserving link: $target_path"
        exit 0
      fi

      if [ -e "$target_path" ]; then
        echo "[$display_name] Existing item is not owned by this module."
        echo "[$display_name] Preserving item: $target_path"
        exit 0
      fi

      echo "[$display_name] Managed application link is already absent."
    '';
in

{
  # ------------------------------------------------------------
  # ------ CLAUDE OPTIONS ------ #
  # ------------------------------------------------------------

  options.ven.packages.claude = {
    enable =
      lib.mkEnableOption "Claude packages and configuration"
      // {
        default = true;
      };

    code = {
      enable =
        lib.mkEnableOption "Claude Code CLI"
        // {
          default = true;
        };

      configDirectory = lib.mkOption {
        type = lib.types.str;
        default = "/Users/ven/.config/claude";
        description = ''
          Directory used by Claude Code instead of ~/.claude.
        '';
      };

      memoryDataDirectory = lib.mkOption {
        type = lib.types.str;
        default = "/Users/ven/.config/claude-mem";
        description = ''
          Directory used by the Claude Memory plugin.
        '';
      };

      executablePath = lib.mkOption {
        type = lib.types.str;
        default = "/run/current-system/sw/bin/claude";
        description = ''
          System path exposed to tools that need the Claude Code executable.
        '';
      };

      disableAutoUpdater = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disables Claude Code's built-in updater because Nix manages it.
        '';
      };
    };

    desktop = {
      enable =
        lib.mkEnableOption "Claude Desktop"
        // {
          default = true;
        };

      displayName = lib.mkOption {
        type = lib.types.str;
        default = "Claude";
        description = ''
          Human-readable name used in activation output.
        '';
      };

      package = {
        version = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.version;
          description = ''
            Claude Desktop release version.
          '';
        };

        releaseId = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.releaseId;
          description = ''
            Release identifier used in Anthropic's archive filename.
          '';
        };

        sourceHash = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.sourceHash;
          description = ''
            Nix hash of the official Claude Desktop archive.
          '';
        };

        downloadUrl = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.downloadUrl;
          description = ''
            Complete URL of the official Claude Desktop archive.
          '';
        };

        applicationName = lib.mkOption {
          type = lib.types.str;
          default = "Claude.app";
          description = ''
            Application bundle name inside Anthropic's archive.
          '';
        };
      };

      link = {
        enable =
          lib.mkEnableOption "Claude Desktop application link"
          // {
            default = true;
          };

        sourceDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Applications/Nix Apps";
          description = ''
            Directory where nix-darwin exposes Nix-managed applications.
          '';
        };

        targetDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Applications";
          description = ''
            Directory where the optional Claude Desktop link is created.
          '';
        };
      };
    };

    npm = {
      userConfigPath = lib.mkOption {
        type = lib.types.str;
        default = "/Users/ven/.config/npm/npmrc";
        description = ''
          npm user configuration path exported for Claude Code.
        '';
      };

      cacheDirectory = lib.mkOption {
        type = lib.types.str;
        default = "/Users/ven/.config/npm/cache";
        description = ''
          npm cache directory exported for Claude Code.
        '';
      };
    };
  };

  # ------------------------------------------------------------
  # ------ CLAUDE CONFIGURATION ------ #
  # ------------------------------------------------------------

  config = lib.mkMerge [
    {
      ven.packages.claude = {
        enable =
          lib.mkDefault claudeSettings.enable;

        code.enable =
          lib.mkDefault claudeSettings.code.enable;

        desktop = {
          enable =
            lib.mkDefault claudeSettings.desktop.enable;

          link.enable =
            lib.mkDefault claudeSettings.desktop.link.enable;
        };
      };

      environment.systemPackages =
        enabledClaudePackages;
    }

    # Export Claude Code variables only when the main module and
    # Claude Code are enabled.
    (lib.mkIf (cfg.enable && cfg.code.enable) {
      environment.variables =
        claudeEnvironment;

      launchd.user.envVariables =
        claudeEnvironment;
    })

    # Run the link manager even when Claude Desktop or its link is
    # disabled, allowing a previously managed link to be removed.
    (lib.mkIf isDarwin {
      system.activationScripts.postActivation.text =
        lib.mkAfter ''
          ${manageClaudeDesktopLink}/bin/manage-claude-desktop-link
        '';
    })
  ];
}