# darwin/packages/claude/default.nix
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
	# Provides access to the evaluated nix-darwin configuration.
  config,

  # Provides Nix module helpers, option types, and conditional functions.
  lib,

  # Provides packages and package-building functions from nixpkgs.
  pkgs,

  # Accepts additional module arguments without requiring them here.
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
  	# Eenable the entire Claude module and all its features
    enable = true;

    # Enable the Claude Code CLI package and its environment variables
    code = {
      enable = true;
    };

    # Enable the Claude Desktop package and its optional application link
    desktop = {
      enable = true;

      # Enable the optional application link for Claude Desktop
      link = {
        enable = true;
      };
    };
  };

  # Creates a shorter name for the evaluated Claude option set.
  cfg = config.ven.packages.claude;

  # Platform detection
  ## Evaluates to true when the current target system is macOS.
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # ------ CLAUDE DESKTOP RELEASE
  # ------------------------------------------------------------
  # Imports the generated Claude Desktop release information from
  # claude-desktop-release.nix in this same directory.
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

  #
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

  # Builds the environment-variable set exported for Claude Code.
  claudeEnvironment =
    {
      # Tells Claude Code where to store its main configuration.
      CLAUDE_CONFIG_DIR =
        cfg.code.configDirectory;

      # Tells the Claude Memory plugin where to store its data.
      CLAUDE_MEM_DATA_DIR =
        cfg.code.memoryDataDirectory;

      # Exposes the absolute path to the Nix-managed Claude executable.
      CLAUDE_CODE_PATH =
        cfg.code.executablePath;

      # Tells npm which user-level npm configuration file to use.
      NPM_CONFIG_USERCONFIG =
        cfg.npm.userConfigPath;

      # Tells npm where to store downloaded package cache data.
      NPM_CONFIG_CACHE =
        cfg.npm.cacheDirectory;
    }
    # Add the updater-disabling variable only when the option is enabled.
    // lib.optionalAttrs cfg.code.disableAutoUpdater {
      # Prevent Claude Code from trying to update outside Nix.
      DISABLE_AUTOUPDATER = "1";
    };

  # ------------------------------------------------------------
  # ------ ENABLED PACKAGES ------ #
  # ------------------------------------------------------------

  # Builds the final package list according to the module toggles and
  # the current operating system.
  enabledClaudePackages =
    # Add Claude Code only when both the main module and CLI are enabled.
    lib.optionals
      (cfg.enable && cfg.code.enable)
      [
        # Install the Claude Code CLI from nixpkgs.
        pkgs.claude-code
      ]
    # Append the Claude Desktop packages when Desktop is enabled on macOS.
    ++ lib.optionals
      (
        # Require the complete Claude module to be enabled.
        cfg.enable

        # Require the Claude Desktop feature to be enabled.
        && cfg.desktop.enable

        # Prevent the macOS application from being installed elsewhere.
        && isDarwin
      )
      [
        # Install the packaged Claude Desktop application.
        claudeDesktopPackage

        # Install the release-update command supplied by the package.
        claudeDesktopPackage.updateScriptPackage
      ];

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINK PATHS ------ #
  # ------------------------------------------------------------

  # Builds the full path to the Nix-managed Claude application bundle.
  claudeDesktopSourcePath =
    "${cfg.desktop.link.sourceDirectory}/${cfg.desktop.package.applicationName}";

  # Builds the full path where the optional application link should exist.
  claudeDesktopTargetPath =
    "${cfg.desktop.link.targetDirectory}/${cfg.desktop.package.applicationName}";

  # Determines whether the Claude Desktop application link should exist.
  claudeDesktopLinkShouldExist =
    # Require the complete Claude module to be enabled.
    cfg.enable

    # Require Claude Desktop to be enabled.
    && cfg.desktop.enable

    # Require application-link management to be enabled.
    && cfg.desktop.link.enable

    # Manage the application link only on macOS.
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

  # Creates a Nix-managed command that safely creates, verifies, or
  # removes the optional Claude Desktop application link.
  manageClaudeDesktopLink =
    pkgs.writeShellScriptBin "manage-claude-desktop-link" ''
      # Exit on an error, an unset variable, or a failed pipeline command.
      set -euo pipefail

      # Store the user-facing application name as a shell-safe value.
      display_name=${lib.escapeShellArg cfg.desktop.displayName}

      # Store the expected Nix-managed application path.
      source_path=${lib.escapeShellArg claudeDesktopSourcePath}

      # Store the requested destination path in /Applications.
      target_path=${lib.escapeShellArg claudeDesktopTargetPath}

      # Convert the Nix Boolean into the shell strings true or false.
      should_exist=${lib.escapeShellArg (
        if claudeDesktopLinkShouldExist then
          "true"
        else
          "false"
      )}

      # Determine the directory containing the requested target path.
      target_directory="$(
        ${pkgs.coreutils}/bin/dirname \
          -- \
          "$target_path"
      )"

      # Print the start of application-link management.
      echo "[$display_name] Application link management started."

      # Print the expected source application path.
      echo "[$display_name] Source: $source_path"

      # Print the requested target application path.
      echo "[$display_name] Target: $target_path"

      # Print whether the link is expected to exist.
      echo "[$display_name] Requested state: $should_exist"

      # Validate the source path.
      # ----------------------------------------------------------

      # Accept only application bundles located under /Applications/Nix Apps.
      case "$source_path" in
        "/Applications/Nix Apps/"*.app)
          # Continue when the source path matches the allowed pattern.
          ;;
        *)
          # Report an invalid source path.
          echo "[$display_name] ERROR: Unsupported source path." >&2

          # Print the path that was rejected.
          echo "[$display_name] Refusing source: $source_path" >&2

          # Stop before touching any files.
          exit 1
          ;;
      esac

      # Validate the target path.
      # ----------------------------------------------------------

      # Accept only application bundles directly inside /Applications.
      case "$target_path" in
        /Applications/*.app)
          # Continue when the target path matches the allowed pattern.
          ;;
        *)
          # Report an invalid target path.
          echo "[$display_name] ERROR: Unsupported target path." >&2

          # Print the path that was rejected.
          echo "[$display_name] Refusing target: $target_path" >&2

          # Stop before touching any files.
          exit 1
          ;;
      esac

      # Create or verify the managed link.
      # ----------------------------------------------------------

      # Enter link-creation mode when the link is requested.
      if [ "$should_exist" = "true" ]; then
        # Refuse to create a link when the packaged application is absent.
        if [ ! -d "$source_path" ]; then
          # Explain that the Nix-managed application was not found.
          echo "[$display_name] ERROR: Nix-managed application was not found." >&2

          # Print the path where the application was expected.
          echo "[$display_name] Expected: $source_path" >&2

          # Stop because the link would point to a missing application.
          exit 1
        fi

        # Create the destination directory if it does not exist.
        if [ ! -d "$target_directory" ]; then
          # Announce creation of the target directory.
          echo "[$display_name] Creating target directory."

          # Create the directory and any missing parent directories.
          ${pkgs.coreutils}/bin/mkdir \
            -p \
            -- \
            "$target_directory"
        fi

        # Verify that the destination directory now exists.
        if [ ! -d "$target_directory" ]; then
          # Report that directory creation failed.
          echo "[$display_name] ERROR: Target directory was not created." >&2

          # Stop before attempting to create the link.
          exit 1
        fi

        # Handle an existing symbolic link at the requested destination.
        if [ -L "$target_path" ]; then
          # Read the destination currently used by the existing link.
          existing_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          # Accept the link when it already points to the expected source.
          if [ "$existing_target" = "$source_path" ]; then
            # Report that no change is needed.
            echo "[$display_name] SUCCESS: Application link is already correct."

            # Finish successfully without recreating the link.
            exit 0
          fi

          # Refuse to replace a symbolic link owned by something else.
          echo "[$display_name] ERROR: An unrelated symbolic link exists." >&2

          # Print the existing link destination for diagnosis.
          echo "[$display_name] Existing target: $existing_target" >&2

          # Stop without changing the unrelated link.
          exit 1
        fi

        # Refuse to overwrite any existing non-symlink item.
        if [ -e "$target_path" ]; then
          # Report that the requested location is already occupied.
          echo "[$display_name] ERROR: The target path is occupied." >&2

          # Print the occupied location.
          echo "[$display_name] Existing item: $target_path" >&2

          # Explain that the existing item will be preserved.
          echo "[$display_name] Refusing to replace it." >&2

          # Stop without modifying the existing item.
          exit 1
        fi

        # Announce creation of the managed link.
        echo "[$display_name] Creating application link."

        # Create a symbolic link from /Applications to the Nix-managed app.
        ${pkgs.coreutils}/bin/ln \
          -s \
          -- \
          "$source_path" \
          "$target_path"

        # Verify that a symbolic link now exists at the target path.
        if [ ! -L "$target_path" ]; then
          # Report that link creation failed.
          echo "[$display_name] ERROR: Application link was not created." >&2

          # Stop because the requested state was not reached.
          exit 1
        fi

        # Read the newly created link destination.
        existing_target="$(
          ${pkgs.coreutils}/bin/readlink \
            -- \
            "$target_path"
        )"

        # Verify that the new link points to the expected application.
        if [ "$existing_target" != "$source_path" ]; then
          # Report that the created link points somewhere unexpected.
          echo "[$display_name] ERROR: Application link has the wrong target." >&2

          # Print the actual link destination.
          echo "[$display_name] Actual target: $existing_target" >&2

          # Stop because verification failed.
          exit 1
        fi

        # Report successful link creation and verification.
        echo "[$display_name] SUCCESS: Application link created and verified."

        # Finish successfully.
        exit 0
      fi

      # Remove only the link owned by this module.
      # ----------------------------------------------------------

      # Inspect the target when it currently contains a symbolic link.
      if [ -L "$target_path" ]; then
        # Read the destination used by the existing link.
        existing_target="$(
          ${pkgs.coreutils}/bin/readlink \
            -- \
            "$target_path"
        )"

        # Remove the link only when it points to this module's source.
        if [ "$existing_target" = "$source_path" ]; then
          # Announce removal of the managed link.
          echo "[$display_name] Removing managed application link."

          # Remove the known symbolic link.
          ${pkgs.coreutils}/bin/rm \
            -f \
            -- \
            "$target_path"

          # Verify that neither an item nor a broken link remains.
          if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            # Report that link removal failed.
            echo "[$display_name] ERROR: Managed link was not removed." >&2

            # Stop because the requested state was not reached.
            exit 1
          fi

          # Report successful removal.
          echo "[$display_name] SUCCESS: Managed application link removed."

          # Finish successfully.
          exit 0
        fi

        # Explain that an unrelated symbolic link was found.
        echo "[$display_name] Existing link is not owned by this module."

        # Confirm that the unrelated link will be preserved.
        echo "[$display_name] Preserving link: $target_path"

        # Finish successfully without changing it.
        exit 0
      fi

      # Preserve an existing non-symlink item at the destination.
      if [ -e "$target_path" ]; then
        # Explain that the existing item belongs to something else.
        echo "[$display_name] Existing item is not owned by this module."

        # Confirm that the item will not be removed.
        echo "[$display_name] Preserving item: $target_path"

        # Finish successfully without changing it.
        exit 0
      fi

      # Report that the requested absent state already exists.
      echo "[$display_name] Managed application link is already absent."
    '';
in

{
  # ------------------------------------------------------------
  # ------ CLAUDE OPTIONS ------ #
  # ------------------------------------------------------------
  
  # Options related specifically to Claude Code
  options.ven.packages.claude = {

  # Controls installation and configuration of Claude Code
  enable =

  	  # Creates a Boolean option for enabling the Claude Code CLI
      lib.mkEnableOption "Claude packages and configuration"
      // {

      	# Enable Claude Code unless another module overrides it
        default = true;
      };

    code = {
      enable =
        lib.mkEnableOption "Claude Code CLI"
        // {
          default = true;
        };

      # Controls the location of Claude Code's main configuration  
      configDirectory = lib.mkOption {
      	# Require the option value to be a string
        type = lib.types.str;

        # Use the XDG-style Claude configuration directory by default
        default = "/Users/ven/.config/claude";

        # Describe the option in generated Nix documentation
        description = ''
          Directory used by Claude Code instead of ~/.claude.
        '';
      };

      # Controls the location of Claude Memory plugin data
      memoryDataDirectory = lib.mkOption {
      	# Require the option value to be a string
        type = lib.types.str;

        # Use the XDG-style Claude Memory data directory by default
        default = "/Users/ven/.config/claude-mem";
        description = ''
          Directory used by the Claude Memory plugin.
        '';
      };

      # Controls the system path to the Claude Code executable
      executablePath = lib.mkOption {
        type = lib.types.str;
        default = "/run/current-system/sw/bin/claude";
        description = ''
          System path exposed to tools that need the Claude Code executable.
        '';
      };

      # Controls whether Claude Code's built-in updater is disabled
      disableAutoUpdater = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disables Claude Code's built-in updater because Nix manages it.
        '';
      };
    };

    
    # Controls installation and configuration of Claude Desktop
    desktop = {
      enable =
        lib.mkEnableOption "Claude Desktop"
        // {
          default = true;
        };

      # Controls the human-readable name used in activation output
      displayName = lib.mkOption {
        type = lib.types.str;
        default = "Claude";
        description = ''
          Human-readable name used in activation output.
        '';
      };

    # Options passed to the Claude Desktop package definition
    package = {
        version = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.version;
          description = ''
            Claude Desktop release version.
          '';
        };

        # Controls the release identifier used in Anthropic's archive filename
        releaseId = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.releaseId;
          description = ''
            Release identifier used in Anthropic's archive filename.
          '';
        };

        # Controls the Nix hash of the official Claude Desktop archive
        sourceHash = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.sourceHash;
          description = ''
            Nix hash of the official Claude Desktop archive.
          '';
        };

        # Controls the complete URL of the official Claude Desktop archive
        downloadUrl = lib.mkOption {
          type = lib.types.str;
          default =
            claudeDesktopRelease.downloadUrl;
          description = ''
            Complete URL of the official Claude Desktop archive.
          '';
        };

        # Controls the application bundle name inside Anthropic's archive
        applicationName = lib.mkOption {
          type = lib.types.str;
          default = "Claude.app";
          description = ''
            Application bundle name inside Anthropic's archive.
          '';
        };
      };

      # Controls the optional application link for Claude Desktop
      link = {
        enable =
          lib.mkEnableOption "Claude Desktop application link"
          // {
            default = true;
          };

        # Controls the source directory where Nix-managed applications are exposed
        sourceDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Applications/Nix Apps";
          description = ''
            Directory where nix-darwin exposes Nix-managed applications.
          '';
        };

        # Controls the target directory where the optional application link is created
        targetDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Applications";
          description = ''
            Directory where the optional Claude Desktop link is created.
          '';
        };
      };
    };


    # Controls npm configuration paths used by Claude Code
    npm = {

      # Controls the user-level npm configuration file path used by Claude Code 
      userConfigPath = lib.mkOption {
        type = lib.types.str;
        default = "/Users/ven/.config/npm/npmrc";
        description = ''
          npm user configuration path exported for Claude Code.
        '';
      };

      # Controls the npm cache directory used by Claude Code
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

  # Merges the evaluated Claude options into the final nix-darwin configuration.
  config = lib.mkMerge [
    {
      ven.packages.claude = {
        enable =
          # Enable the entire Claude module and all its features
          lib.mkDefault claudeSettings.enable;


        # ------ CLAUDE CODE CONFIGURATION ------ #
        code.enable =
          # Enable the Claude Code CLI package and its environment variables
          lib.mkDefault claudeSettings.code.enable;

        # --- CLAUDE DESKTOP CONFIGURATION --- #
        desktop = {
          enable =
          	# Enable the Claude Desktop package and its optional application link
            lib.mkDefault claudeSettings.desktop.enable;

          link.enable =
            # Enable the optional application link for Claude Desktop
            lib.mkDefault claudeSettings.desktop.link.enable;
        };
      };

      # Merges the evaluated Claude options into the final nix-darwin configuration
      environment.systemPackages =
        enabledClaudePackages;
    }

    # Export Claude Code variables only when the main module and
    # Claude Code are enabled.
    (lib.mkIf (cfg.enable && cfg.code.enable) {
      # Export Claude Code variables to the system environment for CLI applications
      environment.variables =
        claudeEnvironment;

      # Export Claude Code variables to launchd for GUI applications
      launchd.user.envVariables =
        claudeEnvironment;
    })

    # Run the link manager even when Claude Desktop or its link is
    # disabled, allowing a previously managed link to be removed.
    (lib.mkIf isDarwin {
      # Activation script for managing the optional Claude Desktop application link
      system.activationScripts.postActivation.text =
        lib.mkAfter ''
          ${manageClaudeDesktopLink}/bin/manage-claude-desktop-link
        '';
    })
  ];
}