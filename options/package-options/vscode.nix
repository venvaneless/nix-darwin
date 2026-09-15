# options/package-options/vscode.nix
#
# =====================================================================
# PACKAGE OPTIONS: VISUAL STUDIO CODE
# =====================================================================
#
# Defines VS Code's package, application-link, and mutable-state
# semantics. shared/packages.nix selects every concrete value.
# =====================================================================

{ config, lib, paths, platforms, ... }:

let
  cfg = config.system.sharedPackages.developmentApplications.vscode;

  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform cfg;

  # One mutable source can serve several standard VS Code locations.
  stateLocations = [
    { source = cfg.paths.source.extensions; targets = cfg.paths.symlink.extensions; }
    { source = cfg.paths.source.userData; targets = cfg.paths.symlink.userData; }
    { source = cfg.paths.source.sharedData; targets = cfg.paths.symlink.sharedData; }
    { source = cfg.paths.source.argv; targets = cfg.paths.symlink.argv; }
    { source = cfg.paths.source.cli; targets = cfg.paths.symlink.cli; }
    { source = cfg.paths.source.agentPlugins; targets = cfg.paths.symlink.agentPlugins; }
  ];

  # This nested module is evaluated by Home Manager. The surrounding option
  # module owns the rendering rules; Home Manager owns the user-level links.
  darwinStateLinks = { config, lib, ... }:
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
    in
    {
      # ---- Mutable VS Code state
      # The standard paths are out-of-store links to live user-owned data.
      home.file = homeFiles;
    };
in
{
  # Installed and linked by the developmentApplications group.
  options.system.sharedPackages.developmentApplications = lib.mkOption {
    type = lib.types.submodule ({ config, ... }: {
      options.vscode = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.enable;
          description = "Install Visual Studio Code. Defaults to its group.";
        };

        installOn = lib.mkOption {
          type = lib.types.attrsOf lib.types.bool;
          default = config.installOn;
          description = "Platforms on which VS Code is installed. Defaults to its group.";
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
        };
      };
    });
  };

  config = lib.mkMerge [
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
