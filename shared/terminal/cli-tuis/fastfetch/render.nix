# shared/terminal/cli-tuis/fastfetch/render.nix
#
# =====================================================================
# FASTFETCH: LAYOUT RENDERING HELPERS
#
# Plain helper set, imported directly by the layout modules rather than
# evaluated as a Home Manager module, following options/paths.nix.
#
# Fastfetch colours a key by embedding raw ANSI escapes in the key
# string itself, which is why the layouts cannot simply hand it a hex
# value. These helpers keep that escape plumbing in one place so the
# layout files stay readable lists of modules.
# =====================================================================

{ lib }:

let
  # ------------------------------------------------------------
  # ------ ANSI PRIMITIVES ------ #
  # ------------------------------------------------------------

  # Nix has no escape sequence for the ESC control character, so it is
  # decoded from JSON. builtins.toJSON re-escapes it as \u001b when the
  # layout is serialised, which is what fastfetch expects to read.
  escape = builtins.fromJSON ''"\u001b"'';

  reset = "${escape}[0m";

  # ------------------------------------------------------------
  # ------ HEX TO TRUECOLOR ------ #
  # ------------------------------------------------------------

  hexValues = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };

  digit =
    character:
    hexValues.${lib.toLower character}
      or (throw "fastfetch: \"${character}\" is not a hexadecimal digit");

  # Reads one #rrggbb channel starting at the given offset.
  channel =
    hex: offset: (digit (builtins.substring offset 1 hex)) * 16 + (digit (builtins.substring (offset + 1) 1 hex));

  # "#fabd2f" -> "250;189;47"
  components =
    colour:
    let
      hex = lib.removePrefix "#" colour;
    in
    if builtins.stringLength hex != 6 then
      throw ''fastfetch: expected a "#rrggbb" colour but got "${colour}"''
    else
      "${toString (channel hex 0)};${toString (channel hex 2)};${toString (channel hex 4)}";

  # Foreground escape for a palette colour.
  foreground = colour: "${escape}[38;2;${components colour}m";
in
{
  inherit escape reset foreground components;

  # ------------------------------------------------------------
  # ------ SECTION HEADINGS ------ #
  # ------------------------------------------------------------

  # A full-width rule that introduces a section, drawn in its accent.
  rule = section: text: {
    type = "custom";
    format = "${foreground section.accent}${text}${reset}";
  };

  # Vertical space between sections.
  blank = {
    type = "custom";
    format = "";
  };

  # ------------------------------------------------------------
  # ------ INFORMATION ROWS ------ #
  # ------------------------------------------------------------

  # One key/value row. The icon and label take the section accent, the
  # " : " separator takes its label colour, and the value is printed in
  # the accent by fastfetch itself.
  #
  # prefix carries box-drawing characters for framed layouts.
  # extra passes module specific options such as temp or format through.
  entry =
    section:
    {
      type,
      icon,
      text,
      prefix ? "",
      extra ? { },
    }:
    {
      inherit type;
      key = "${foreground section.accent}${prefix}${icon} ${text}${foreground section.label} : ${reset}";
      outputColor = section.accent;
    }
    // extra;
}
