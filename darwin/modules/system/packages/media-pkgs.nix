# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/media-pkgs.nix
#
# =====================================================================
# PACKAGES: DARWIN MEDIA APPLICATIONS
#
# Installs media applications available specifically through Darwin
# package definitions:
# - Per-application installation toggles
# - Declarative application category links
# - Link collision protection
# - Link creation and removal verification
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ DARWIN MEDIA APPLICATION DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the package is installed.
  #
  # link.enable:
  #   Controls whether the application is linked into its
  #   categorized directory under /Applications.
  #
  # Keeping the link block while disabling either toggle allows
  # the activation script to remove links previously created by
  # this module.
  # ------------------------------------------------------------

  darwinMediaApplications = {
    # ---- VLC
    # Uses the official precompiled ARM64 VLC application package.
    vlc = {
      displayName = "VLC";
      enable = true;
      package = pkgs.vlc-bin;

      link = {
        enable = true;
        appName = "VLC.app";
        targetDirectory = "/Applications/Multimedia";
      };
    };
  };

  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  #
  # Selects enabled Darwin media applications for installation.
  # ------------------------------------------------------------

  enabledDarwinMediaPackages =
    map
      (application: application.package)
      (
        lib.filter
          (application: application.enable)
          (lib.attrValues darwinMediaApplications)
      );

  # ------------------------------------------------------------
  # ------ MANAGED APPLICATION LINKS ------ #
  #
  # Keeps every application containing a link definition in the
  # management list, including disabled applications.
  #
  # This allows enable = false or link.enable = false to remove
  # a link previously created by this module.
  # ------------------------------------------------------------

  managedDarwinApplicationLinks =
    lib.filter
      (application: application ? link)
      (lib.attrValues darwinMediaApplications);

  renderManagedApplicationLink =
    application:

    let
      sourcePath =
        "/Applications/Nix Apps/${application.link.appName}";

      targetPath =
        "${application.link.targetDirectory}/${application.link.appName}";

      shouldExist =
        application.enable
        && application.link.enable;
    in

    ''
      manage_application_link \
        ${lib.escapeShellArg application.displayName} \
        ${lib.escapeShellArg sourcePath} \
        ${lib.escapeShellArg targetPath} \
        ${lib.escapeShellArg (
          if shouldExist then
            "true"
          else
            "false"
        )}
    '';

  managedApplicationLinkCommands =
    lib.concatMapStringsSep
      "\n"
      renderManagedApplicationLink
      managedDarwinApplicationLinks;

  # ------------------------------------------------------------
  # ------ APPLICATION LINK MANAGER ------ #
  #
  # Creates and removes only symbolic links owned by this module.
  #
  # Existing application bundles, unrelated symbolic links, files,
  # scripts, and extensions are never overwritten or deleted.
  # ------------------------------------------------------------

  manageDarwinMediaApplicationLinks =
    pkgs.writeShellScriptBin "manage-darwin-media-application-links" ''
      set -euo pipefail

      manage_application_link() {
        local display_name="$1"
        local source_path="$2"
        local target_path="$3"
        local should_exist="$4"
        local target_directory
        local current_target

        target_directory="$(
          ${pkgs.coreutils}/bin/dirname -- "$target_path"
        )"

        echo "[$display_name] Application link management started."
        echo "[$display_name] Source: $source_path"
        echo "[$display_name] Target: $target_path"
        echo "[$display_name] Requested link state: $should_exist"

        # Only manage macOS application bundles
        # ------------------------------------------------------------
        case "$source_path" in
          "/Applications/Nix Apps/"*.app)
            ;;
          *)
            echo "[$display_name] ERROR: Refusing unsupported source path: $source_path" >&2
            return 1
            ;;
        esac

        case "$target_path" in
          /Applications/*.app)
            ;;
          *)
            echo "[$display_name] ERROR: Refusing unsupported target path: $target_path" >&2
            return 1
            ;;
        esac

        # Link enabled
        # ------------------------------------------------------------
        if [ "$should_exist" = "true" ]; then
          if [ ! -d "$source_path" ]; then
            echo "[$display_name] ERROR: Nix-managed application was not found." >&2
            echo "[$display_name] Expected application: $source_path" >&2
            return 1
          fi

          if [ ! -d "$target_directory" ]; then
            echo "[$display_name] Creating application category directory: $target_directory"

            ${pkgs.coreutils}/bin/mkdir \
              -p \
              -- \
              "$target_directory"

            if [ ! -d "$target_directory" ]; then
              echo "[$display_name] ERROR: Failed to create category directory." >&2
              return 1
            fi

            echo "[$display_name] SUCCESS: Category directory created."
          else
            echo "[$display_name] Category directory already exists."
          fi

          if [ -L "$target_path" ]; then
            current_target="$(
              ${pkgs.coreutils}/bin/readlink \
                -- \
                "$target_path"
            )"

            if [ "$current_target" = "$source_path" ]; then
              echo "[$display_name] SUCCESS: Application link is already correct."
              return 0
            fi

            echo "[$display_name] ERROR: Refusing to replace an unrelated symbolic link." >&2
            echo "[$display_name] Existing link target: $current_target" >&2
            return 1
          fi

          if [ -e "$target_path" ]; then
            echo "[$display_name] ERROR: Refusing to replace an existing application or file." >&2
            echo "[$display_name] Existing item: $target_path" >&2
            echo "[$display_name] Check whether the old Homebrew application is still installed." >&2
            return 1
          fi

          echo "[$display_name] Creating categorized application link."

          ${pkgs.coreutils}/bin/ln \
            -s \
            -- \
            "$source_path" \
            "$target_path"

          if [ ! -L "$target_path" ]; then
            echo "[$display_name] ERROR: Application link was not created." >&2
            return 1
          fi

          current_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          if [ "$current_target" != "$source_path" ]; then
            echo "[$display_name] ERROR: Application link points to the wrong target." >&2
            echo "[$display_name] Actual target: $current_target" >&2
            return 1
          fi

          echo "[$display_name] SUCCESS: Application link created and verified."
          return 0
        fi

        # Link disabled
        # ------------------------------------------------------------
        if [ -L "$target_path" ]; then
          current_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          if [ "$current_target" = "$source_path" ]; then
            echo "[$display_name] Removing application link owned by this module."

            ${pkgs.coreutils}/bin/rm \
              -f \
              -- \
              "$target_path"

            if [ -e "$target_path" ] || [ -L "$target_path" ]; then
              echo "[$display_name] ERROR: Managed application link was not removed." >&2
              return 1
            fi

            echo "[$display_name] SUCCESS: Managed application link removed."
            return 0
          fi

          echo "[$display_name] Existing symbolic link is not owned by this module."
          echo "[$display_name] Preserving unrelated link: $target_path"
          return 0
        fi

        if [ -e "$target_path" ]; then
          echo "[$display_name] Existing item is not owned by this module."
          echo "[$display_name] Preserving existing item: $target_path"
          return 0
        fi

        echo "[$display_name] Application link is already absent."
      }

      echo "[Darwin media applications] Starting application link management."

      ${managedApplicationLinkCommands}

      echo "[Darwin media applications] All application links processed successfully."
    '';
in

{
  # ------------------------------------------------------------
  # ------ DARWIN MEDIA PACKAGES ------ #
  #
  # Installs enabled macOS-specific media packages.
  # ------------------------------------------------------------

  environment.systemPackages =
    enabledDarwinMediaPackages;

  # ------------------------------------------------------------
  # ------ DARWIN MEDIA APPLICATION LINKS ------ #
  #
  # Runs after nix-darwin application installation and Homebrew
  # cleanup so category links point to the final Nix-managed apps.
  # ------------------------------------------------------------

  system.activationScripts.postActivation.text =
    lib.mkAfter ''
      ${manageDarwinMediaApplicationLinks}/bin/manage-darwin-media-application-links
    '';
}