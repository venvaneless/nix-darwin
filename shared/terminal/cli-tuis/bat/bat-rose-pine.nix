# shared/terminal/cli-tuis/bat/bat-rose-pine.nix
#
# =====================================================================
# BAT: ROSÉ PINE MOON THEME
#
# - Declares the Rosé Pine Moon tmTheme entirely in Nix
# - Selected directly in bat.nix with selectedTheme = "rosePine"
# - Enabled only when bat.nix imports this theme module
#
# Home Manager writes the generated theme into bat's config directory
# and runs `bat cache --build` during activation.
#
# bat.nix imports only one selected theme module at a time.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  batCfg = config.ven.features.terminal.cliTuis.bat;
  cfg = batCfg.rosePine;

  # ---- THEME IDENTITY ---- #
  # bat reports the theme under this name.
  themeName = "Rose-Pine-Moon";

  # ---- ROSÉ PINE MOON PALETTE ---- #
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

  # ---- GENERATED TMTHEME ---- #
  # TextMate property list consumed by bat's syntax highlighter.
  themeFile = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Rose Pine Moon</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key>
          <dict>
            <key>background</key>
            <string>${palette.base}</string>
            <key>caret</key>
            <string>${palette.text}</string>
            <key>foreground</key>
            <string>${palette.text}</string>
            <key>invisibles</key>
            <string>${palette.muted}</string>
            <key>lineHighlight</key>
            <string>${palette.overlay}</string>
            <key>selection</key>
            <string>${palette.highlight}</string>
            <key>findHighlight</key>
            <string>${palette.foam}</string>
            <key>findHighlightForeground</key>
            <string>${palette.base}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Comment</string>
          <key>scope</key>
          <string>comment, punctuation.definition.comment</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.muted}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>String</string>
          <key>scope</key>
          <string>string, string.quoted, punctuation.definition.string</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.gold}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Number</string>
          <key>scope</key>
          <string>constant.numeric, constant.language</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.foam}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Keyword</string>
          <key>scope</key>
          <string>keyword, keyword.control, keyword.operator.word, storage.type, storage.modifier</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.pine}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Operator</string>
          <key>scope</key>
          <string>keyword.operator, punctuation.separator, punctuation.accessor</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.subtle}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Function</string>
          <key>scope</key>
          <string>entity.name.function, support.function, meta.function-call</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.rose}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Type / Class</string>
          <key>scope</key>
          <string>entity.name.type, entity.name.class, entity.other.inherited-class, support.type</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.foam}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Variable</string>
          <key>scope</key>
          <string>variable, variable.parameter, variable.language</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.text}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Constant / Boolean</string>
          <key>scope</key>
          <string>constant, constant.character, constant.other</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.rosewater}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Tag / Attribute</string>
          <key>scope</key>
          <string>entity.name.tag, entity.other.attribute-name, markup.bold</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.iris}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Invalid / Error</string>
          <key>scope</key>
          <string>invalid, invalid.illegal</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.love}</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Markdown heading / title</string>
          <key>scope</key>
          <string>markup.heading, entity.name.section</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${palette.love}</string>
            <key>fontStyle</key>
            <string>bold</string>
          </dict>
        </dict>
      </array>
    </dict>
    </plist>
  '';

  # Home Manager's bat themes take a directory plus a file name.
  themeDir = pkgs.writeTextDir "${themeName}.tmTheme" themeFile;
in
{
  options.ven.features.terminal.cliTuis.bat.rosePine.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use the Rosé Pine Moon syntax theme for bat.";
  };

  # Only applies when bat itself is enabled.
  config = lib.mkIf (batCfg.enable && cfg.enable) {
    programs.bat = {
      # ---- THEME SELECTION ---- #
      config.theme = themeName;

      # ---- THEME DEFINITION ---- #
      themes.${themeName} = {
        src = themeDir;
        file = "${themeName}.tmTheme";
      };
    };
  };
}
