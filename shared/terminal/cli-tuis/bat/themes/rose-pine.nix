# shared/terminal/cli-tuis/bat/themes/rose-pine.nix
#
# =====================================================================
# BAT THEME: ROSÉ PINE MOON
#
# Every colour of the generated tmTheme. The file itself is written by
# options/cli/bat/themes/helper.nix.
# =====================================================================

{ ... }:

{
  home.shared.cli.bat.themes.rosePine = {
    name = "rosePine";
    batName = "Rose-Pine-Moon";
    title = "Rose Pine Moon";

    palette = {
      base = "#191724";
      overlay = "#2a273f";
      highlight = "#44415a";
      muted = "#6e6a86";
      subtle = "#908caa";
      text = "#e0def4";
      love = "#eb6f92";
      gold = "#f6c177";
      rose = "#ea9a97";
      pine = "#3e8fb0";
      foam = "#9ccfd8";
      iris = "#c4a7e7";
      rosewater = "#ebbcba";
    };

    editor = {
      background = "base";
      caret = "text";
      foreground = "text";
      invisibles = "muted";
      lineHighlight = "overlay";
      selection = "highlight";
      findHighlight = "foam";
      findHighlightForeground = "base";
    };

    scopes = {
      "Comment" = {
        scope = "comment, punctuation.definition.comment";
        foreground = "muted";
        fontStyle = "italic";
      };

      "String" = {
        scope = "string, string.quoted, punctuation.definition.string";
        foreground = "gold";
      };

      "Number" = {
        scope = "constant.numeric, constant.language";
        foreground = "foam";
      };

      "Keyword" = {
        scope = "keyword, keyword.control, keyword.operator.word, storage.type, storage.modifier";
        foreground = "pine";
      };

      "Operator" = {
        scope = "keyword.operator, punctuation.separator, punctuation.accessor";
        foreground = "subtle";
      };

      "Function" = {
        scope = "entity.name.function, support.function, meta.function-call";
        foreground = "rose";
      };

      "Type / Class" = {
        scope = "entity.name.type, entity.name.class, entity.other.inherited-class, support.type";
        foreground = "foam";
      };

      "Variable" = {
        scope = "variable, variable.parameter, variable.language";
        foreground = "text";
      };

      "Constant / Boolean" = {
        scope = "constant, constant.character, constant.other";
        foreground = "rosewater";
      };

      "Tag / Attribute" = {
        scope = "entity.name.tag, entity.other.attribute-name, markup.bold";
        foreground = "iris";
      };

      "Invalid / Error" = {
        scope = "invalid, invalid.illegal";
        foreground = "love";
      };

      "Markdown heading / title" = {
        scope = "markup.heading, entity.name.section";
        foreground = "love";
        fontStyle = "bold";
      };
    };
  };
}
