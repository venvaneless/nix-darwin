# darwin/packages/helper.nix
#
# =====================================================================
# HELPER: DARWIN APPLICATION LINKS
#
# Creates and removes categorized symbolic links for Nix-managed
# macOS application bundles.
#
# Safety:
# - Never replaces regular files or directories
# - Never replaces unrelated symbolic links
# - Removes only links pointing to the expected managed source
# - Leaves application bundles in /Applications/Nix Apps untouched
# =====================================================================

{ lib, pkgs }:

{
  applications,

  sourceDirectory ? "/Applications/Nix Apps",
  targetDirectory,

  managerName,
}:

let

  # ------------------------------------------------------------
  # ------ MANAGED APPLICATIONS ------ #
  #
  # Entries without appName are treated as non-GUI packages and
  # are excluded from application-link management.
  # ------------------------------------------------------------

  managedApplications =
    lib.filter
      (application:
        (application.appName or null) != null
      )
      (lib.attrValues applications);


  # ------------------------------------------------------------
  # ------ LINK COMMAND RENDERER ------ #
  # ------------------------------------------------------------

  renderApplicationLink =
    application:

    let
      displayName =
        application.displayName or application.appName;

      sourcePath =
        "${sourceDirectory}/${application.appName}";

      targetPath =
        "${targetDirectory}/${application.appName}";

      shouldExist =
        (application.enable or false)
        && (application.link or false);

      shouldExistState =
        if shouldExist then
          "true"
        else
          "false";
    in

    ''
      manage_application_link \
        ${lib.escapeShellArg displayName} \
        ${lib.escapeShellArg sourcePath} \
        ${lib.escapeShellArg targetPath} \
        ${lib.escapeShellArg shouldExistState}
    '';


  # ------------------------------------------------------------
  # ------ GENERATED LINK COMMANDS ------ #
  # ------------------------------------------------------------

  applicationLinkCommands =
    lib.concatMapStringsSep
      "\n"
      renderApplicationLink
      managedApplications;


  # ------------------------------------------------------------
  # ------ APPLICATION LINK MANAGER ------ #
  # ------------------------------------------------------------

  linkManager =
    pkgs.writeShellScriptBin managerName ''
      set -euo pipefail


      manage_application_link() {
        local display_name="$1"
        local source_path="$2"
        local target_path="$3"
        local should_exist="$4"

        local target_directory
        local current_target

        target_directory="$(
          ${pkgs.coreutils}/bin/dirname \
            -- "$target_path"
        )"

        # ------------------------------------------------------
        # Create or validate the managed link
        # ------------------------------------------------------

        if [ "$should_exist" = "true" ]; then
          if [ ! -d "$source_path" ]; then
            echo "[$display_name] ERROR: Nix-managed application was not found." >&2
            echo "[$display_name] Expected source: $source_path" >&2
            return 1
          fi

          ${pkgs.coreutils}/bin/mkdir \
            -p \
            -- "$target_directory"

          if [ -L "$target_path" ]; then
            current_target="$(
              ${pkgs.coreutils}/bin/readlink \
                -- "$target_path"
            )"

            if [ "$current_target" = "$source_path" ]; then
              return 0
            fi

            echo "[$display_name] ERROR: Refusing to replace an unrelated symbolic link." >&2
            echo "[$display_name] Existing target: $current_target" >&2
            echo "[$display_name] Expected target: $source_path" >&2
            return 1
          fi

          if [ -e "$target_path" ]; then
            echo "[$display_name] ERROR: Refusing to replace an existing item." >&2
            echo "[$display_name] Existing item: $target_path" >&2
            return 1
          fi

          ${pkgs.coreutils}/bin/ln \
            -s \
            -- "$source_path" \
            "$target_path"

          echo "[$display_name] Application link created."
          return 0
        fi

        # ------------------------------------------------------
        # Remove only a link managed by this configuration
        # ------------------------------------------------------

        if [ -L "$target_path" ]; then
          current_target="$(
            ${pkgs.coreutils}/bin/readlink \
              -- "$target_path"
          )"

          if [ "$current_target" = "$source_path" ]; then
            ${pkgs.coreutils}/bin/rm \
              -f \
              -- "$target_path"

            return 0
          fi
        fi

        return 0
      }

      ${applicationLinkCommands}
    '';
in
{
  inherit
    linkManager
    managedApplications
    ;
}