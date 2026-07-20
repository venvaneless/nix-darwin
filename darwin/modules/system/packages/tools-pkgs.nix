# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/tools-pkgs.nix
#
# =====================================================================
# PACKAGES: DARWIN TOOLS
#
# Installs macOS-only utility applications:
# - Menu bar utilities
# - General-purpose tools
# - Developer-adjacent utilities
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ CUSTOM PACKAGES ------ #
  # ------------------------------------------------------------

  assetsnapPackage =
    pkgs.callPackage ./assetsnap.nix { };

  hammerspoonPackage =
    pkgs.callPackage ./hammerspoon.nix { };

  # ------------------------------------------------------------
  # ------ TOOL DEFINITIONS ------ #
  #
  # enable:
  #   Installs or removes the package.
  #
  # link.enable:
  #   Creates or removes the categorized application symlink.
  # ------------------------------------------------------------

  toolApplications = {
    # ---- AssetSnap
    # Provides developer assets from the macOS menu bar.
    assetsnap = {
      displayName = "AssetSnap";
      enable = true;
      package = assetsnapPackage;

      link = {
        enable = true;
        appName = "AssetSnap.app";
        targetDirectory = "/Applications/Tools";
      };
    };

  # ---- Hammerspoon
  # Automates macOS using Lua scripts and native system APIs.
  hammerspoon = {
    displayName = "Hammerspoon";
    enable = true;
    package = hammerspoonPackage;
  
    link = {
      enable = true;
      appName = "Hammerspoon.app";
      targetDirectory = "/Applications/Tools";
    };
  };
};

  # ------------------------------------------------------------
  # ------ ENABLED PACKAGES ------ #
  # ------------------------------------------------------------

  enabledToolPackages =
    map
      (application: application.package)
      (
        lib.filter
          (application: application.enable)
          (lib.attrValues toolApplications)
      );

  # ------------------------------------------------------------
  # ------ MANAGED LINKS ------ #
  # ------------------------------------------------------------

  managedToolLinks =
    lib.filter
      (application: application ? link)
      (lib.attrValues toolApplications);

  renderToolLink =
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

  managedToolLinkCommands =
    lib.concatMapStringsSep
      "\n"
      renderToolLink
      managedToolLinks;

  # ------------------------------------------------------------
  # ------ LINK MANAGER ------ #
  # ------------------------------------------------------------

  manageToolApplicationLinks =
    pkgs.writeShellScriptBin "manage-darwin-tool-application-links" ''
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

        echo "[$display_name] Source: $source_path"
        echo "[$display_name] Target: $target_path"
        echo "[$display_name] Requested state: $should_exist"

        if [ "$should_exist" = "true" ]; then
          if [ ! -d "$source_path" ]; then
            echo "[$display_name] ERROR: Nix-managed application was not found." >&2
            echo "[$display_name] Expected: $source_path" >&2
            return 1
          fi

          ${pkgs.coreutils}/bin/mkdir \
            -p \
            -- \
            "$target_directory"

          if [ -L "$target_path" ]; then
            current_target="$(
              ${pkgs.coreutils}/bin/readlink \
                -- \
                "$target_path"
            )"

            if [ "$current_target" = "$source_path" ]; then
              echo "[$display_name] Application link is already correct."
              return 0
            fi

            echo "[$display_name] ERROR: Refusing to replace an unrelated link." >&2
            echo "[$display_name] Existing target: $current_target" >&2
            return 1
          fi

          if [ -e "$target_path" ]; then
            echo "[$display_name] ERROR: Refusing to replace an existing item." >&2
            echo "[$display_name] Existing item: $target_path" >&2
            return 1
          fi

          ${pkgs.coreutils}/bin/ln \
            -s \
            -- \
            "$source_path" \
            "$target_path"

          echo "[$display_name] Application link created."
          return 0
        fi

        if [ -L "$target_path" ]; then
          current_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- \
              "$target_path"
          )"

          if [ "$current_target" = "$source_path" ]; then
            ${pkgs.coreutils}/bin/rm \
              -f \
              -- \
              "$target_path"

            echo "[$display_name] Managed application link removed."
            return 0
          fi
        fi

        echo "[$display_name] No managed application link to remove."
      }

      echo "[Darwin tools] Starting application link management."

      ${managedToolLinkCommands}

      echo "[Darwin tools] Application link management complete."
    '';
in

{
  # ------------------------------------------------------------
  # ------ DARWIN TOOL PACKAGES ------ #
  # ------------------------------------------------------------

  environment.systemPackages =
    enabledToolPackages;

  # ------------------------------------------------------------
  # ------ DARWIN TOOL LINKS ------ #
  # ------------------------------------------------------------

  system.activationScripts.postActivation.text =
    lib.mkAfter ''
      ${manageToolApplicationLinks}/bin/manage-darwin-tool-application-links
    '';
}