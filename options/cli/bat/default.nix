# options/cli/bat/default.nix
#
# =====================================================================
# OPTIONS: BAT
#
# Owns bat's option shape, platform selection, Home Manager
# implementation, and theme files. shared/terminal/cli-tuis assigns
# every user-facing bat knob.
# =====================================================================

{ config, lib, platforms, pkgs, ... }:

let
  cfg = config.home.shared.cli.bat;

  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform cfg;

  # Theme values remain shared knobs, while this option module owns their
  # discovery and imports alongside Bat's theme schema and rendering.
  sharedThemeDirectory = ../../../shared/terminal/cli-tuis/bat/themes;
  themeFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name
  ) (builtins.readDir sharedThemeDirectory);
in
{
  # Theme knob schema, selector, rendering, and every shared theme value.
  imports = [
    ./themes/helper.nix
  ] ++ map (name: sharedThemeDirectory + "/${name}") (lib.attrNames themeFiles);

  options.home.shared.cli.bat = {
    enable = lib.mkEnableOption "Bat file viewer";

    installOn = {
      darwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure bat on macOS.";
      };

      linux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure bat on Linux.";
      };
    };

    enabledForCurrentPlatform = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether bat is enabled for the Home Manager host currently being built.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ style = "numbers,changes,header"; }'';
      description = "bat settings written to its config file. The theme is set by the theme knob.";
    };

    rebuildCache = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Rebuild bat's syntax cache during activation, quietly. Home Manager
        rebuilds it anyway; this keeps its messages about empty custom-theme
        folders out of the log.
      '';
    };
  };

  config = lib.mkMerge [
    {
      home.shared.cli.bat.enabledForCurrentPlatform = enabledForCurrentPlatform;
    }

    (lib.mkIf enabledForCurrentPlatform {
      programs.bat = {
        enable = true;

        # The selected theme sets config.theme in themes/helper.nix.
        config = cfg.settings;
      };
    })

    (lib.mkIf (enabledForCurrentPlatform && cfg.rebuildCache) {
      home.activation.batCache = lib.mkForce (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          (
            export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
            cd "${pkgs.emptyDirectory}"
            run ${lib.getExe config.programs.bat.package} cache --build >/dev/null 2>&1
          )
        ''
      );
    })
  ];
}
