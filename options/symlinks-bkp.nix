# options/symlinks.nix
#
# =====================================================================
# OPTIONS: DARWIN APPLICATION LINKS
#
# Converts flat package flags into guarded macOS application links. The
# generated manager only creates category directories and only removes
# links that point to its expected Nix-managed application bundle.
# =====================================================================

{ lib, paths, pkgs }:

let
  # ------------------------------------------------------------
  # ------ APPLICATION LINK CATEGORIES ------ #
  # ------------------------------------------------------------

  linkCategories = [
    {
      flag = "symlinkApplications";
      targetDirectory = paths.darwin.applications.root;
    }
    {
      flag = "symlinkProgramming";
      targetDirectory = paths.darwin.applications.programming;
    }
    {
      flag = "symlinkProductivity";
      targetDirectory = paths.darwin.applications.productivity;
    }
    {
      flag = "symlinkTools";
      targetDirectory = paths.darwin.applications.tools;
    }
    {
      flag = "symlinkMultimedia";
      targetDirectory = paths.darwin.applications.multimedia;
    }
    {
      flag = "symlinkSystem";
      targetDirectory = paths.darwin.applications.system;
    }
  ];

  # ------------------------------------------------------------
  # ------ APPLICATION LINK MANAGER ------ #
  # ------------------------------------------------------------

  mkApplicationLinkManager = { name, packages }:
    let
      applicationPackages = lib.filter (package: package ? appName) (lib.attrValues packages);

      validateApplication = package:
        let
          enabledCategories = lib.filter
            (category: package.${category.flag} or false)
            linkCategories;
        in
        if builtins.length enabledCategories > 1 then
          throw "${name}: ${package.appName} enables more than one Darwin application-link category"
        else
          package;

      validatedApplications = map validateApplication applicationPackages;

      renderApplicationLinks = package:
        let
          sourcePath = "${paths.darwin.applications.nixApps}/${package.appName}";
          shouldInstall = (package.enable or false) && ((package.installOn.darwin or false));
        in
        lib.concatMapStringsSep "\n"
          (category:
            let
              shouldLink = shouldInstall && (package.${category.flag} or false);
            in
            ''
              manage_application_link \
                ${lib.escapeShellArg package.appName} \
                ${lib.escapeShellArg sourcePath} \
                ${lib.escapeShellArg "${category.targetDirectory}/${package.appName}"} \
                ${lib.escapeShellArg (if shouldLink then "true" else "false")}
            '')
          linkCategories;

      linkCommands = lib.concatMapStringsSep "\n" renderApplicationLinks validatedApplications;
    in
    pkgs.writeShellScriptBin "manage-${name}-application-links" ''
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

        # Only Nix-managed bundles may be used as link sources.
        case "$source_path" in
          "${paths.darwin.applications.nixApps}/"*.app)
            ;;
          *)
            echo "[$app_name] ERROR: Unsupported application source: $source_path" >&2
            return 1
            ;;
        esac

        # Links may only be created inside the managed Applications tree.
        case "$target_path" in
          "${paths.darwin.applications.root}/"*.app)
            ;;
          *)
            echo "[$app_name] ERROR: Unsupported application target: $target_path" >&2
            return 1
            ;;
        esac

        if [ "$should_exist" = "true" ]; then
          if [ ! -d "$source_path" ]; then
            echo "[$app_name] ERROR: Nix-managed application was not found: $source_path" >&2
            return 1
          fi

          ${pkgs.coreutils}/bin/mkdir -p -- "$target_directory"

          if [ -L "$target_path" ]; then
            existing_target="$(
              ${pkgs.coreutils}/bin/readlink -- "$target_path"
            )"

            if [ "$existing_target" = "$source_path" ]; then
              return 0
            fi

            echo "[$app_name] ERROR: Refusing to replace an unrelated symbolic link: $target_path" >&2
            return 1
          fi

          if [ -e "$target_path" ]; then
            echo "[$app_name] ERROR: Refusing to replace an existing item: $target_path" >&2
            return 1
          fi

          ${pkgs.coreutils}/bin/ln -s -- "$source_path" "$target_path"
          echo "[$app_name] Created application link: $target_path"
          return 0
        fi

        # Remove only the exact link this configuration owns.
        if [ -L "$target_path" ]; then
          existing_target="$(
            ${pkgs.coreutils}/bin/readlink -- "$target_path"
          )"

          if [ "$existing_target" = "$source_path" ]; then
            ${pkgs.coreutils}/bin/rm -f -- "$target_path"
            echo "[$app_name] Removed managed application link: $target_path"
          fi
        fi
      }

      ${linkCommands}
    '';
in
{
  inherit linkCategories mkApplicationLinkManager;
}
