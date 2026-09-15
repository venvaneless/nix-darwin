# options/package-options/vscode.nix
#
# =====================================================================
# PACKAGE OPTIONS: VISUAL STUDIO CODE
# =====================================================================
#
# Defines VS Code's package, application-link, and mutable-state
# semantics. shared/packages.nix selects every concrete value.
# =====================================================================

{ config, lib, packageOptions, paths, platforms, symlinks ? null, ... }:

let
  cfg = config.ven.packages.vscode;

  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform {
    enable = cfg.enable;
    installOn = cfg.installOn;
  };

  vscodePackage = {
    inherit (cfg) enable installOn package appName symlinkProgramming;
  };

  # One mutable source can serve several standard VS Code locations.
  stateLocations = [
    { name = "extensions"; kind = "directory"; source = cfg.paths.source.extensions; targets = cfg.paths.symlink.extensions; }
    { name = "user-data"; kind = "directory"; source = cfg.paths.source.userData; targets = cfg.paths.symlink.userData; }
    { name = "shared-data"; kind = "directory"; source = cfg.paths.source.sharedData; targets = cfg.paths.symlink.sharedData; }
    { name = "argv"; kind = "file"; source = cfg.paths.source.argv; targets = cfg.paths.symlink.argv; }
    { name = "cli"; kind = "directory"; source = cfg.paths.source.cli; targets = cfg.paths.symlink.cli; }
    { name = "agent-plugins"; kind = "directory"; source = cfg.paths.source.agentPlugins; targets = cfg.paths.symlink.agentPlugins; }
  ];

  sourceDirectories = lib.unique (
    lib.concatMap
      (location:
        if location.kind == "directory" then
          [ location.source ]
        else
          [ builtins.dirOf location.source ])
      stateLocations
  );

  sourceDirectoryArguments =
    lib.concatMapStringsSep " " lib.escapeShellArg sourceDirectories;

  # This nested module is evaluated by Home Manager. The surrounding option
  # module owns the rendering rules; Home Manager owns the user-level links.
  darwinStateLinks = { config, lib, pkgs, ... }:
    let
      homePrefix = "${config.home.homeDirectory}/";

      relativeTarget = target:
        if lib.hasPrefix homePrefix target then
          lib.removePrefix homePrefix target
        else
          throw "vscode: Home Manager can only link paths below ${config.home.homeDirectory}: ${target}";

      homeFiles = lib.listToAttrs (
        lib.concatMap
          (location:
            map
              (target: {
                name = relativeTarget target;
                value.source = config.lib.file.mkOutOfStoreSymlink location.source;
              })
              location.targets)
          stateLocations
      );

      migrationCalls = lib.concatMapStringsSep "\n" (location:
        lib.concatMapStringsSep "\n" (target: ''
          migrate_vscode_location \
            ${lib.escapeShellArg location.kind} \
            ${lib.escapeShellArg location.source} \
            ${lib.escapeShellArg target} \
            ${lib.escapeShellArg location.name}
        '') location.targets
      ) stateLocations;
    in
    {
      # ---- Mutable VS Code state
      # The standard paths are out-of-store links to live user-owned data.
      home.file = homeFiles;

      # ---- One-time non-destructive migration
      # Existing default locations are merged without overwriting the source,
      # then retained under a dated backup before Home Manager links them.
      home.activation.migrateVscodeStateLinks =
        lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          set -euo pipefail

          migration_root=${lib.escapeShellArg cfg.paths.migrationBackups}
          migration_stamp="$(/bin/date +%Y-%m-%d_%H-%M-%S)"

          migrate_vscode_location() {
            kind="$1"
            source_path="$2"
            target_path="$3"
            location_name="$4"

            if [ -L "$target_path" ]; then
              link_target="$(/usr/bin/readlink "$target_path")"
              if [ "$link_target" = "$source_path" ]; then
                return
              fi

              echo "[vscode] Refusing to replace unexpected link: $target_path -> $link_target" >&2
              exit 1
            fi

            if [ ! -e "$target_path" ]; then
              return
            fi

            if /usr/bin/pgrep -f 'Visual Studio Code\.app/Contents/MacOS/' >/dev/null; then
              echo "[vscode] Quit Visual Studio Code before migrating $target_path." >&2
              exit 1
            fi

            backup_path="$migration_root/$migration_stamp/$location_name/$(/usr/bin/basename "$target_path")"
            ''${DRY_RUN_CMD} /bin/mkdir -p "$(/usr/bin/dirname "$backup_path")"

            case "$kind" in
              directory)
                if [ ! -d "$target_path" ]; then
                  echo "[vscode] Refusing to replace non-directory target: $target_path" >&2
                  exit 1
                fi

                ''${DRY_RUN_CMD} ${pkgs.rsync}/bin/rsync \
                  --archive \
                  --ignore-existing \
                  -- "$target_path/" "$source_path/"
                ;;
              file)
                if [ ! -f "$target_path" ]; then
                  echo "[vscode] Refusing to replace non-file target: $target_path" >&2
                  exit 1
                fi

                if [ ! -e "$source_path" ]; then
                  ''${DRY_RUN_CMD} /bin/mv "$target_path" "$source_path"
                  return
                fi
                ;;
              *)
                echo "[vscode] Unknown migration kind: $kind" >&2
                exit 1
                ;;
            esac

            ''${DRY_RUN_CMD} /bin/mv "$target_path" "$backup_path"
            echo "[vscode] Preserved $target_path at $backup_path."
          }

          ''${DRY_RUN_CMD} /bin/mkdir -p ${sourceDirectoryArguments}

          ${migrationCalls}
        '';
    };
in
{
  options.ven.packages.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";

    installOn = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      description = "Platforms on which VS Code is installed.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "VS Code package to install.";
    };

    appName = lib.mkOption {
      type = lib.types.str;
      description = "VS Code application bundle name.";
    };

    symlinkProgramming = lib.mkOption {
      type = lib.types.bool;
      description = "Link VS Code into the Darwin Programming application category.";
    };

    paths = {
      source = {
        extensions = lib.mkOption { type = lib.types.str; description = "Mutable source-of-truth directory for extensions."; };
        userData = lib.mkOption { type = lib.types.str; description = "Mutable source-of-truth directory for user data."; };
        sharedData = lib.mkOption { type = lib.types.str; description = "Mutable source-of-truth directory for shared data."; };
        argv = lib.mkOption { type = lib.types.str; description = "Mutable source-of-truth file for argv.json."; };
        cli = lib.mkOption { type = lib.types.str; description = "Mutable source-of-truth directory for CLI state."; };
        agentPlugins = lib.mkOption { type = lib.types.str; description = "Mutable source-of-truth directory for agent plugins."; };
      };

      symlink = {
        extensions = lib.mkOption { type = lib.types.listOf lib.types.str; description = "Extension destinations."; };
        userData = lib.mkOption { type = lib.types.listOf lib.types.str; description = "User-data destinations."; };
        sharedData = lib.mkOption { type = lib.types.listOf lib.types.str; description = "Shared-data destinations."; };
        argv = lib.mkOption { type = lib.types.listOf lib.types.str; description = "argv.json destinations."; };
        cli = lib.mkOption { type = lib.types.listOf lib.types.str; description = "CLI-state destinations."; };
        agentPlugins = lib.mkOption { type = lib.types.listOf lib.types.str; description = "Agent-plugin destinations."; };
      };

      migrationBackups = lib.mkOption {
        type = lib.types.str;
        description = "Directory retaining pre-link VS Code state during migration.";
      };
    };
  };

  config = lib.mkMerge [
    (packageOptions.mkPackageModule {
      name = "vscode";
      packages = { vscode = vscodePackage; };
      inherit symlinks;
    })

    (lib.mkIf (enabledForCurrentPlatform && platforms.isDarwin) {
      home-manager.users.${paths.user.name} = darwinStateLinks;
    })

    # Linux keeps its current portable environment until its Home Manager
    # graph receives the same standard-location link implementation.
    (lib.mkIf (enabledForCurrentPlatform && platforms.isLinux) {
      environment.variables = {
        VSCODE_PORTABLE = builtins.dirOf cfg.paths.source.extensions;
        VSCODE_CLI_DATA_DIR = cfg.paths.source.cli;
      };
    })
  ];
}
