# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/development-pkgs.nix
#
# =====================================================================
# PACKAGES: DEVELOPMENT TOOLS
#
# Installs development and document-building tools:
# - Git helpers
# - Nix language tooling
# - Docker CLI
# - Node.js and Python
# - Pandoc and LaTeX/PDF tooling
# - macOS development applications
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ CUSTOM TEX LIVE ENVIRONMENT ------ #
  # ------------------------------------------------------------

  # ---- Custom TeX Live environment
  # Combines a medium TeX Live scheme with extra LaTeX packages
  # needed by Pandoc and PDF workflows.
  myTex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium titlesec;
  };

  # ------------------------------------------------------------
  # ------ CUSTOM APPLICATION PACKAGES ------ #
  # ------------------------------------------------------------

  # ---- iTerm2
  iterm2Package =
    pkgs.callPackage ./iterm2 { };

  # ---- iTerm AI Plugin
  itermAiPluginPackage =
    pkgs.callPackage ./iterm2/iterm-ai-plugin.nix { };

  # ---- iTerm Browser Plugin
  itermBrowserPluginPackage =
    pkgs.callPackage ./iterm2/iterm-browser-plugin.nix { };

  # ------------------------------------------------------------
  # ------ DEVELOPMENT CLI PACKAGES ------ #
  # ------------------------------------------------------------

  developmentPackages = with pkgs; [
    bitwarden-cli
    delta
    docker_29
    docker-compose
    git-crypt
    git-filter-repo
    git-lfs
    home-manager
    direnv
    nix-direnv
    lazygit
    myTex
    nil
    nix-index
    nixd
    nixfmt
    nodejs
    nssTools
    pandoc
    prettier
    python3
    python3Packages.pandas
    python3Packages.reportlab
    stylelint
    stylua
  ];

  # ------------------------------------------------------------
  # ------ DEVELOPMENT APPLICATIONS ------ #
  #
  # enable:
  #   Installs or removes the application package.
  #
  # link.enable:
  #   Creates or removes the categorized application symlink.
  # ------------------------------------------------------------

  developmentApplications = {
    # ---- iTerm2
    iterm2 = {
      displayName = "iTerm2";
      enable = true;
      package = iterm2Package;
  
      link = {
        enable = true;
        appName = "iTerm.app";
        targetDirectory = "/Applications/Programming";
      };
    };
  
    # ---- iTerm AI Plugin
    itermAiPlugin = {
      displayName = "iTerm AI Plugin";
      enable = true;
      package = itermAiPluginPackage;
  
      link = {
        enable = true;
        appName = "iTermAI.app";
        targetDirectory = "/Applications/Programming";
      };
    };
  
    # ---- iTerm Browser Plugin
    itermBrowserPlugin = {
      displayName = "iTerm Browser Plugin";
      enable = true;
      package = itermBrowserPluginPackage;
  
      link = {
        enable = true;
        appName = "iTermBrowserPlugin.app";
        targetDirectory = "/Applications/Programming";
      };
    };
  };

  # ------------------------------------------------------------
  # ------ ENABLED APPLICATION PACKAGES ------ #
  # ------------------------------------------------------------

  enabledDevelopmentApplicationPackages =
    map
      (application: application.package)
      (
        lib.filter
          (application: application.enable)
          (lib.attrValues developmentApplications)
      );

  # ------------------------------------------------------------
  # ------ MANAGED APPLICATION LINKS ------ #
  # ------------------------------------------------------------

  managedDevelopmentApplicationLinks =
    lib.filter
      (application: application ? link)
      (lib.attrValues developmentApplications);

  renderDevelopmentApplicationLink =
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

  managedDevelopmentApplicationLinkCommands =
    lib.concatMapStringsSep
      "\n"
      renderDevelopmentApplicationLink
      managedDevelopmentApplicationLinks;

  # ------------------------------------------------------------
  # ------ APPLICATION LINK MANAGER ------ #
  # ------------------------------------------------------------

  manageDevelopmentApplicationLinks =
    pkgs.writeShellScriptBin
      "manage-darwin-development-application-links"
      ''
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

        echo "[Darwin development] Starting application link management."

        ${managedDevelopmentApplicationLinkCommands}

        echo "[Darwin development] Application link management complete."
      '';
in

{
  # ------------------------------------------------------------
  # ------ DEVELOPMENT PACKAGES ------ #
  # ------------------------------------------------------------

  environment.systemPackages =
    developmentPackages
    ++ enabledDevelopmentApplicationPackages;

  # ------------------------------------------------------------
  # ------ DEVELOPMENT APPLICATION LINKS ------ #
  # ------------------------------------------------------------

  system.activationScripts.postActivation.text =
    lib.mkAfter ''
      ${manageDevelopmentApplicationLinks}/bin/manage-darwin-development-application-links
    '';
}