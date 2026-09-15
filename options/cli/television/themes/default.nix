# options/cli/television/themes/default.nix
#
# =====================================================================
# OPTIONS: TELEVISION THEMES
#
# Declares one knob set that every named theme reuses, the uiTheme
# selector, and renders only the selected theme to the TOML file its
# knobs name. Each theme's values, including its name and output file,
# live in their own file next to this one.
# =====================================================================

{ config, lib, paths, pkgs, ... }:

let
  cfg = config.home.shared.cli.television;

  # Television only finds themes inside its own themes directory.
  themesDirectory = "${paths.relative.config}/television/themes/";

  # ------------------------------------------------------------
  # ------ SHARED COLOUR KNOBS ------ #
  # Every leaf names the Television theme key it renders to. Knob groups
  # follow Television's own sections; unset (null) colours are omitted.
  # ------------------------------------------------------------

  colourKeys = {
    general = {
      background = { key = "background"; description = "Window background colour."; };
      borderFg = { key = "border_fg"; description = "Panel border colour."; };
      textFg = { key = "text_fg"; description = "Default text colour."; };
      dimmedTextFg = { key = "dimmed_text_fg"; description = "Secondary, dimmed text colour."; };
    };

    input = {
      textFg = { key = "input_text_fg"; description = "Search input text colour."; };
      resultCountFg = { key = "result_count_fg"; description = "Result counter colour."; };
    };

    results = {
      nameFg = { key = "result_name_fg"; description = "Result name colour."; };
      lineNumberFg = { key = "result_line_number_fg"; description = "Result line number colour."; };
      valueFg = { key = "result_value_fg"; description = "Result value colour."; };
      selectionFg = { key = "selection_fg"; description = "Selected result text colour."; };
      selectionBg = { key = "selection_bg"; description = "Selected result background colour."; };
      matchFg = { key = "match_fg"; description = "Matched characters colour."; };
    };

    preview = {
      titleFg = { key = "preview_title_fg"; description = "Preview panel title colour."; };
    };

    modes = {
      channel = {
        fg = { key = "channel_mode_fg"; description = "Channel mode indicator text colour."; };
        bg = { key = "channel_mode_bg"; description = "Channel mode indicator background colour."; };
      };

      remoteControl = {
        fg = { key = "remote_control_mode_fg"; description = "Remote control mode indicator text colour."; };
        bg = { key = "remote_control_mode_bg"; description = "Remote control mode indicator background colour."; };
      };

      actionPicker = {
        fg = { key = "action_picker_mode_fg"; description = "Action picker mode indicator text colour."; };
        bg = { key = "action_picker_mode_bg"; description = "Action picker mode indicator background colour."; };
      };
    };
  };

  isColourLeaf = value: value ? key;

  colourOptions = lib.mapAttrsRecursiveCond (value: !isColourLeaf value) (
    _: leaf:
    lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = leaf.description;
    }
  ) colourKeys;

  # ------------------------------------------------------------
  # ------ ONE THEME ------ #
  # Identity and output file are knobs too, so each theme file decides
  # which TOML file it is written to.
  # ------------------------------------------------------------

  themeType = lib.types.submodule (
    { name, ... }:
    {
      options = colourOptions // {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Theme name selected by uiTheme. Must match the attribute name.";
        };

        title = lib.mkOption {
          type = lib.types.str;
          description = "Human-readable theme title.";
        };

        description = lib.mkOption {
          type = lib.types.str;
          description = "What this theme changes.";
        };

        relativePath = lib.mkOption {
          type = lib.types.str;
          example = ".config/television/themes/ven-gruvbox.toml";
          description = ''
            Home-relative TOML file this theme is written to. Its file name,
            without .toml, is the theme name written to config.toml.
          '';
        };
      };
    }
  );

  selectedTheme = cfg.themes.${cfg.uiTheme} or null;

  # ------------------------------------------------------------
  # ------ THEME RENDERING ------ #
  # Walks the knob tree alongside the key table and produces Television's
  # flat theme file from the colours that are set.
  # ------------------------------------------------------------

  flattenTheme =
    keys: values:
    lib.concatMapAttrs (
      name: spec:
      if isColourLeaf spec then
        lib.optionalAttrs (values.${name} != null) { ${spec.key} = values.${name}; }
      else
        flattenTheme spec values.${name}
    ) keys;
in
{
  imports = [
    # Each theme's knob values.
    ./gruvbox.nix
  ];

  options.home.shared.cli.television = {
    uiTheme = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Theme selected for Television. default keeps Television's own palette.";
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf themeType;
      default = { };
      description = "Every named Television theme, each set in its own knob file.";
    };
  };

  config = lib.mkIf cfg.enabledForCurrentPlatform {
    assertions =
      [
        {
          assertion = cfg.uiTheme == "default" || selectedTheme != null;
          message = ''
            home.shared.cli.television.uiTheme is "${cfg.uiTheme}",
            which is not one of: default, ${lib.concatStringsSep ", " (lib.attrNames cfg.themes)}
          '';
        }
      ]
      ++ lib.concatLists (
        lib.mapAttrsToList (attrName: theme: [
          {
            assertion = theme.name == attrName;
            message = ''
              home.shared.cli.television.themes.${attrName}.name is "${theme.name}",
              but it must match the attribute name "${attrName}".
            '';
          }
          {
            assertion =
              lib.hasPrefix themesDirectory theme.relativePath && lib.hasSuffix ".toml" theme.relativePath;
            message = ''
              home.shared.cli.television.themes.${attrName}.relativePath is "${theme.relativePath}",
              but Television only loads .toml themes from ${themesDirectory}.
            '';
          }
        ]) cfg.themes
      );

    home.file = lib.optionalAttrs (selectedTheme != null) {
      ${selectedTheme.relativePath}.source =
        (pkgs.formats.toml { }).generate (baseNameOf selectedTheme.relativePath) (
          flattenTheme colourKeys selectedTheme
        );
    };
  };
}
