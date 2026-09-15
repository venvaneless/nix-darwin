# options/symlinks.nix
#
# =====================================================================
# OPTIONS: DARWIN APPLICATION LINKS
#
# Provides only guarded Darwin application-link behavior. Its caller supplies
# already stripped link entries; this helper neither declares options nor reads
# configuration.
# =====================================================================

{ lib, paths, pkgs, platforms }:

let
  # ------------------------------------------------------------
  # ------ APPLICATION LINK FLAGS ------ #
  # Kept separately from category destinations so package validation can
  # reject link requests that do not describe an application bundle.
  symlinkFlags = [
    "symlinkApplications"
    "symlinkProgramming"
    "symlinkProductivity"
    "symlinkTools"
    "symlinkMultimedia"
    "symlinkSystem"
  ];

  # ------------------------------------------------------------
  # ------ APPLICATION LINK CATEGORIES ------ #
  # ------------------------------------------------------------

  linkCategories = [
    { flag = "symlinkApplications"; targetDirectory = paths.darwin.applications.root; }
    { flag = "symlinkProgramming"; targetDirectory = paths.darwin.applications.programming; }
    { flag = "symlinkProductivity"; targetDirectory = paths.darwin.applications.productivity; }
    { flag = "symlinkTools"; targetDirectory = paths.darwin.applications.tools; }
    { flag = "symlinkMultimedia"; targetDirectory = paths.darwin.applications.multimedia; }
    { flag = "symlinkSystem"; targetDirectory = paths.darwin.applications.system; }
  ];

  # ------------------------------------------------------------
  # ------ APPLICATION LINK MANAGER ------ #
  # Uses only link-entry fields: enable, appName, and category flags.
  # ------------------------------------------------------------

  mkApplicationLinkManager = { name, applications }:
    let
      validateApplication = application:
        let
          enabledCategories = lib.filter
            (flag: application.${flag} or false)
            symlinkFlags;
        in
        if builtins.length enabledCategories > 1 then
          throw "${name}: ${application.appName} enables more than one Darwin application-link category"
        else
          application;

      validatedApplications = map validateApplication (lib.attrValues applications);

      renderApplicationLinks = application:
        let
          sourcePath = "${paths.darwin.applications.nixApps}/${application.appName}";
          shouldInstall = application.enable or false;
        in
        lib.concatMapStringsSep "\n"
          (category:
            let
              shouldLink = shouldInstall && (application.${category.flag} or false);
            in
            ''
              manage_application_link \
                ${lib.escapeShellArg application.appName} \
                ${lib.escapeShellArg sourcePath} \
                ${lib.escapeShellArg "${category.targetDirectory}/${application.appName}"} \
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
          "${paths.darwin.applications.nixApps}/"*.app) ;;
          *)
            echo "[$app_name] ERROR: Unsupported application source: $source_path" >&2
            return 1
            ;;
        esac

        # Links may only be created inside the managed Applications tree.
        case "$target_path" in
          "${paths.darwin.applications.root}/"*.app) ;;
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

  # ------------------------------------------------------------
  # ------ DARWIN LINK ACTIVATION ------ #
  # The link helper owns the safe reconciliation hook after Nix application
  # bundles are available under /Applications/Nix Apps.
  # ------------------------------------------------------------

  mkApplicationLinkModule = { name, applications }:
    lib.mkIf (platforms.isDarwin && applications != { }) {
      system.activationScripts.applications.text = lib.mkAfter ''
        ${mkApplicationLinkManager { inherit name applications; }}/bin/manage-${name}-application-links
      '';
    };
in
{
  inherit linkCategories mkApplicationLinkManager mkApplicationLinkModule symlinkFlags;
}
