# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/media-pkgs.nix

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ DARWIN MEDIA APPLICATION DEFINITIONS ------ #
  # ------------------------------------------------------------

  darwinMediaApplications = {
    # ---- VLC
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

  enabledDarwinMediaPackages =
    map
      (application: application.package)
      (
        lib.filter
          (application: application.enable)
          (lib.attrValues darwinMediaApplications)
      );

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

        if [ "$should_exist" = "true" ]; then
          if [ ! -d "$source_path" ]; then
            echo "[$display_name] ERROR: Nix-managed application was not found." >&2
            echo "[$display_name] Expected application: $source_path" >&2
            return 1
          fi

          if [ ! -d "$target_directory" ]; then
            ${pkgs.coreutils}/bin/mkdir \
              -p \
              -- \
              "$target_directory"
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
            return 1
          fi

          ${pkgs.coreutils}/bin/ln \
            -s \
            -- \
            "$source_path" \
            "$target_path"

          echo "[$display_name] SUCCESS: Application link created."
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

            echo "[$display_name] SUCCESS: Managed application link removed."
            return 0
          fi
        fi

        echo "[$display_name] No managed application link to remove."
      }

      echo "[Darwin media applications] Starting application link management."

      ${managedApplicationLinkCommands}

      echo "[Darwin media applications] All application links processed successfully."
    '';
in

{
  environment.systemPackages =
    enabledDarwinMediaPackages;

  system.activationScripts.postActivation.text =
    lib.mkAfter ''
      ${manageDarwinMediaApplicationLinks}/bin/manage-darwin-media-application-links
    '';
}