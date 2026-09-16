# options/cli/atuin/themes/helper.nix
#
# =====================================================================
# OPTIONS: ATUIN THEMES
#
# Shared theme knobs every Atuin theme reuses, the theme selector, and
# the theme file the selected theme is written to.
# =====================================================================

{ config, lib, paths, ... }:

let
  cfg = config.home.shared.cli.atuin;

  themeType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Theme name selected by theme. Must match the attribute name.";
        };

        atuinName = lib.mkOption {
          type = lib.types.str;
          example = "gruvbox-dark";
          description = "Name Atuin reads from its config and theme file.";
        };

        relativePath = lib.mkOption {
          type = lib.types.str;
          default = "atuin/themes/${name}.toml";
          description = "Config-relative theme file this theme is written to.";
        };

        colours = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = lib.literalExpression ''{ Base = "#ebdbb2"; Title = "#83a598"; }'';
          description = "Colour Atuin uses for each part of its interface.";
        };
      };
    }
  );

  selectedTheme = cfg.themes.${cfg.theme} or null;

  renderTheme = theme: ''
    [theme]
    name = "${theme.atuinName}"

    [colors]
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (part: colour: ''${part} = "${colour}"'') theme.colours
    )}
  '';
in
{
  options.home.shared.cli.atuin = {
    theme = lib.mkOption {
      type = lib.types.str;
      default = "none";
      example = "gruvboxDark";
      description = "Theme Atuin uses, or none to keep Atuin's own default.";
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf themeType;
      default = { };
      description = "Every named Atuin theme, each set in its own knob file.";
    };
  };

  config = lib.mkIf cfg.enabledForCurrentPlatform (
    lib.mkMerge [
      {
        assertions =
          [
            {
              assertion = cfg.theme == "none" || selectedTheme != null;
              message = ''
                home.shared.cli.atuin.theme is "${cfg.theme}",
                which is not one of: none, ${lib.concatStringsSep ", " (lib.attrNames cfg.themes)}
              '';
            }
          ]
          ++ lib.mapAttrsToList (attrName: theme: {
            assertion = theme.name == attrName;
            message = ''
              home.shared.cli.atuin.themes.${attrName}.name is "${theme.name}",
              but it must match the attribute name "${attrName}".
            '';
          }) cfg.themes;
      }

      # Atuin reads one theme name from config.toml, so only the selected
      # theme's file is written.
      (lib.mkIf (selectedTheme != null) {
        xdg.configFile.${selectedTheme.relativePath}.text = renderTheme selectedTheme;

        programs.atuin.settings.theme.name = selectedTheme.atuinName;
      })
    ]
  );
}
