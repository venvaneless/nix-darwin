# /Users/ven/.config/nix/nix-config/shared/packages/media-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED MEDIA TOOLS
#
# Installs media packages shared between Darwin and Linux:
# - Media inspection tools
# - PDF rendering utilities
# - Shared media applications
#
# Each package provides:
# - A global enable or disable toggle
# - A Darwin installation toggle
# - A Linux installation toggle
# - Optional Darwin application category links
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM DETECTION ------ #
  #
  # Determines which operating system is currently evaluating
  # this shared package module.
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ SHARED MEDIA PACKAGE DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the package exists at all.
  #
  # installOn.darwin:
  #   Controls whether the package is installed on macOS.
  #
  # installOn.linux:
  #   Controls whether the package is installed on Linux.
  #
  # darwinLink:
  #   Optionally creates a symbolic link from the application in
  #   /Applications/Nix Apps to another /Applications directory.
  # ------------------------------------------------------------

  mediaPackages = {
    # ---- Kiwix
    # Provides the platform-specific Kiwix offline content reader.
    kiwix = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package =
        if isDarwin then
          pkgs.kiwix-apple
        else if isLinux then
          pkgs.kiwix
        else
          throw "Kiwix is not configured for this platform";

      darwinLink = {
        enable = true;
        appName = "Kiwix.app";
        targetDirectory = "/Applications";
      };
    };

    # ---- MediaInfo
    # Inspects technical and tag information in media files.
    mediainfo = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.mediainfo;
    };

    # ---- Poppler
    # Provides command-line utilities for rendering and inspecting PDFs.
    poppler = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.poppler-utils;
    };

    # ---- YouTube Music Desktop
    # Provides the shared YouTube Music desktop application.
    ytmdesktop = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.ytmdesktop;
    };
  };

  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  #
  # Selects only packages that are enabled for the system that
  # is currently evaluating this module.
  # ------------------------------------------------------------

  enabledForCurrentSystem =
    mediaPackage:
      mediaPackage.enable
      && (
        (isDarwin && mediaPackage.installOn.darwin)
        || (isLinux && mediaPackage.installOn.linux)
      );

  enabledMediaPackages =
    map
      (mediaPackage: mediaPackage.package)
      (
        lib.filter
          enabledForCurrentSystem
          (lib.attrValues mediaPackages)
      );

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINKS ------ #
  #
  # Keeps all applications with a darwinLink definition in the
  # management list, including disabled applications.
  #
  # This allows disabling an application or its link to remove
  # a previously created symbolic link.
  # ------------------------------------------------------------

  managedDarwinApplicationLinks =
    lib.filter
      (mediaPackage: mediaPackage ? darwinLink)
      (lib.attrValues mediaPackages);

  renderDarwinApplicationLink =
    mediaPackage:

    let
      sourcePath =
        "/Applications/Nix Apps/${mediaPackage.darwinLink.appName}";

      targetPath =
        "${mediaPackage.darwinLink.targetDirectory}/${mediaPackage.darwinLink.appName}";

      shouldExist =
        mediaPackage.enable
        && mediaPackage.installOn.darwin
        && mediaPackage.darwinLink.enable;
    in

    ''
      manage_application_link \
        ${lib.escapeShellArg mediaPackage.darwinLink.appName} \
        ${lib.escapeShellArg sourcePath} \
        ${lib.escapeShellArg targetPath} \
        ${lib.escapeShellArg (
          if shouldExist then
            "true"
          else
            "false"
        )}
    '';

  managedDarwinApplicationLinkCommands =
    lib.concatMapStringsSep
      "\n"
      renderDarwinApplicationLink
      managedDarwinApplicationLinks;

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINK MANAGER ------ #
  #
  # Creates and removes only symbolic links managed by this
  # module.
  #
  # Existing application bundles, unrelated symbolic links,
  # scripts, extensions, and other files are never replaced.
  # ------------------------------------------------------------

  manageDarwinMediaApplicationLinks =
    pkgs.writeShellScriptBin "manage-shared-media-application-links" ''
      set -euo pipefail

      manage_application_link() {
        local app_name="$1"
        local source_path="$2"
        local target_path="$3"
        local should_exist="$4"
        local target_directory
        local existing_target

        target_directory="$(
          ${pkgs.coreutils}/bin/dirname -- "$target_path"
        )"

        echo "[$app_name] Application link management started."
        echo "[$app_name] Source: $source_path"
        echo "[$app_name] Target: $target_path"
        echo "[$app_name] Requested state: $should_exist"

        # Validate the source path
        # ------------------------------------------------------------

        case "$source_path" in
          "/Applications/Nix Apps/"*.app)
            ;;
          *)
            echo "[$app_name] ERROR: Unsupported source path." >&2
            echo "[$app_name] Refusing source: $source_path" >&2
            return 1
            ;;
        esac

        # Validate the target path
        # ------------------------------------------------------------

        case "$target_path" in
          /Applications/*.app)
            ;;
          *)
            echo "[$app_name] ERROR: Unsupported target path." >&2
            echo "[$app_name] Refusing target: $target_path" >&2
            return 1
            ;;
        esac

        # Create or verify the application link
        # ------------------------------------------------------------

        if [ "$should_exist" = "true" ]; then
          if [ ! -d "$source_path" ]; then
            echo "[$app_name] ERROR: Nix-managed application was not found." >&2
            echo "[$app_name] Expected: $source_path" >&2
            return 1
          fi

          if [ ! -d "$target_directory" ]; then
            echo "[$app_name] Creating target directory: $target_directory"

            ${pkgs.coreutils}/bin/mkdir \
              -p \
              -- \
              "$target_directory"

            if [ ! -d "$target_directory" ]; then
              echo "[$app_name] ERROR: Target directory was not created." >&2
              return 1
            fi

            echo "[$app_name] SUCCESS: Target directory created."
          else
            echo "[$app_name] Target directory already exists."
          fi

          if [ -L "$target_path" ]; then
            existing_target="$(
              ${pkgs.coreutils}/bin/readlink \
                -- \
                "$target_path"
            )"

            if [ "$existing_target" = "$source_path" ]; then
              echo "[$app_name] SUCCESS: Application link is already correct."
              return 0
            fi

            echo "[$app_name] ERROR: An unrelated symbolic link already exists." >&2
            echo "[$app_name] Existing target: $existing_target" >&2
            return 1
          fi

          if [ -e "$target_path" ]; then
            echo "[$app_name] ERROR: An existing item occupies the target path." >&2
            echo "[$app_name] Existing item: $target_path" >&2
            echo "[$app_name] Refusing to replace it." >&2
            return 1
          fi

          echo "[$app_name] Creating application link."

          ${pkgs.coreutils}/bin/ln \
            -s \
            -- \
            "$source_path" \
            "$target_path"

          if [ ! -L "$target_path" ]; then
            echo "[$app_name] ERROR: Application link was not created." >&2
            return 1
          fi

          existing_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          if [ "$existing_target" != "$source_path" ]; then
            echo "[$app_name] ERROR: Application link has the wrong target." >&2
            echo "[$app_name] Actual target: $existing_target" >&2
            return 1
          fi

          echo "[$app_name] SUCCESS: Application link created and verified."
          return 0
        fi

        # Remove only a link owned by this module
        # ------------------------------------------------------------

        if [ -L "$target_path" ]; then
          existing_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          if [ "$existing_target" = "$source_path" ]; then
            echo "[$app_name] Removing managed application link."

            ${pkgs.coreutils}/bin/rm \
              -f \
              -- \
              "$target_path"

            if [ -e "$target_path" ] || [ -L "$target_path" ]; then
              echo "[$app_name] ERROR: Managed link was not removed." >&2
              return 1
            fi

            echo "[$app_name] SUCCESS: Managed application link removed."
            return 0
          fi

          echo "[$app_name] Existing link is not owned by this module."
          echo "[$app_name] Preserving link: $target_path"
          return 0
        fi

        if [ -e "$target_path" ]; then
          echo "[$app_name] Existing item is not owned by this module."
          echo "[$app_name] Preserving item: $target_path"
          return 0
        fi

        echo "[$app_name] Managed application link is already absent."
      }

      echo "[Shared media applications] Starting application link management."

      ${managedDarwinApplicationLinkCommands}

      echo "[Shared media applications] All application links processed successfully."
    '';
in

{
  config = lib.mkMerge [
    {
      # ------------------------------------------------------------
      # ------ SHARED MEDIA PACKAGES ------ #
      #
      # Installs the filtered media package set for the current
      # Darwin or Linux system.
      # ------------------------------------------------------------

      environment.systemPackages = enabledMediaPackages;
    }

    # ------------------------------------------------------------
    # ------ DARWIN APPLICATION LINK ACTIVATION ------ #
    #
    # Runs only on Darwin and after nix-darwin has populated
    # /Applications/Nix Apps.
    # ------------------------------------------------------------

    (lib.mkIf isDarwin {
      system.activationScripts.postActivation.text =
        lib.mkAfter ''
          ${manageDarwinMediaApplicationLinks}/bin/manage-shared-media-application-links
        '';
    })
  ];
}