# options/cli/bat/themes/helper.nix
#
# =====================================================================
# OPTIONS: BAT THEMES
#
# Shared theme knobs every bat theme reuses, the theme selector, and
# the tmTheme file the selected theme is written to. A built-in theme
# needs no file; bat already ships it.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.home.shared.cli.bat;

  themeType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Theme name selected by theme. Must match the attribute name.";
        };

        batName = lib.mkOption {
          type = lib.types.str;
          example = "gruvbox-dark";
          description = "Name bat knows this theme by, written to bat's config.";
        };

        builtIn = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "The theme ships with bat, so no theme file is generated.";
        };

        title = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Human-readable name stored inside the theme file.";
        };

        palette = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = lib.literalExpression ''{ base = "#191724"; text = "#e0def4"; }'';
          description = "Named colours the theme's rules use.";
        };

        editor = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = lib.literalExpression ''{ background = "base"; foreground = "text"; }'';
          description = "Editor-wide colours, as tmTheme keys mapped to palette names.";
        };

        scopes = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                scope = lib.mkOption {
                  type = lib.types.str;
                  example = "comment, punctuation.definition.comment";
                  description = "Syntax scopes this rule colours.";
                };

                foreground = lib.mkOption {
                  type = lib.types.str;
                  description = "Palette name or hex colour for the matched text.";
                };

                fontStyle = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  example = "italic";
                  description = "Font style for the matched text.";
                };
              };
            }
          );
          default = { };
          description = "Colour rules, one per group of syntax scopes.";
        };
      };
    }
  );

  selectedTheme = cfg.themes.${cfg.theme} or null;

  colour = theme: name: theme.palette.${name} or name;

  # ---- TMTHEME RENDERING ---- #
  # bat's highlighter reads a TextMate property list.

  editorSettings = theme:
    lib.concatStrings (
      lib.mapAttrsToList (key: value: ''
              <key>${key}</key>
              <string>${colour theme value}</string>
      '') theme.editor
    );

  scopeRule = theme: title: rule: ''
          <dict>
            <key>name</key>
            <string>${title}</string>
            <key>scope</key>
            <string>${rule.scope}</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>${colour theme rule.foreground}</string>
    ''
    + lib.optionalString (rule.fontStyle != "") ''
              <key>fontStyle</key>
              <string>${rule.fontStyle}</string>
    ''
    + ''
            </dict>
          </dict>
    '';

  renderTheme = theme: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>${theme.title}</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key>
          <dict>
    ${editorSettings theme}      </dict>
        </dict>
    ${lib.concatStrings (lib.mapAttrsToList (scopeRule theme) theme.scopes)}  </array>
    </dict>
    </plist>
  '';

  themeDirectory = theme: pkgs.writeTextDir "${theme.batName}.tmTheme" (renderTheme theme);
in
{
  options.home.shared.cli.bat = {
    theme = lib.mkOption {
      type = lib.types.str;
      default = "none";
      example = "gruvboxDark";
      description = "Theme bat uses, or none to keep bat's own default.";
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf themeType;
      default = { };
      description = "Every named bat theme, each set in its own knob file.";
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
                home.shared.cli.bat.theme is "${cfg.theme}",
                which is not one of: none, ${lib.concatStringsSep ", " (lib.attrNames cfg.themes)}
              '';
            }
          ]
          ++ lib.mapAttrsToList (attrName: theme: {
            assertion = theme.name == attrName;
            message = ''
              home.shared.cli.bat.themes.${attrName}.name is "${theme.name}",
              but it must match the attribute name "${attrName}".
            '';
          }) cfg.themes;
      }

      (lib.mkIf (selectedTheme != null) {
        programs.bat.config.theme = selectedTheme.batName;
      })

      # A theme bat does not ship is written next to its config.
      (lib.mkIf (selectedTheme != null && !selectedTheme.builtIn) {
        programs.bat.themes.${selectedTheme.batName} = {
          src = themeDirectory selectedTheme;
          file = "${selectedTheme.batName}.tmTheme";
        };
      })
    ]
  );
}
