# options/cli/nvim/lua.nix
#
# =====================================================================
# OPTIONS: NEOVIM LUA WRITER
#
# Turns knob values into the Lua that every Neovim option module writes.
# =====================================================================

{ lib }:

let
  identifier = name: builtins.match "[A-Za-z_][A-Za-z0-9_]*" name != null;

  escape = text:
    lib.replaceStrings
      [ "\\" "\"" "\n" "\t" ]
      [ "\\\\" "\\\"" "\\n" "\\t" ]
      text;

  # Lua written by hand, kept verbatim and re-indented.
  raw = text: { __luaRaw = text; };

  isRaw = value: builtins.isAttrs value && value ? __luaRaw;

  reindent = indent: text:
    let
      lines = lib.splitString "\n" (lib.removeSuffix "\n" text);
      trimmed = lib.filter (line: line != "") lines;
      shortest =
        if trimmed == [ ] then
          0
        else
          lib.foldl' lib.min 1000 (
            map (line: lib.stringLength line - lib.stringLength (lib.removePrefix " " line)) trimmed
          );
      strip = line:
        if line == "" then "" else lib.substring shortest (lib.stringLength line) line;
    in
    lib.concatStringsSep "\n" (
      lib.imap0 (
        index: line:
        if index == 0 then strip line else if line == "" then "" else "${indent}${strip line}"
      ) lines
    );

  render = indent: value:
    let
      inner = "${indent}  ";
    in
    if isRaw value then
      reindent indent value.__luaRaw
    else if value == null then
      "nil"
    else if lib.isBool value then
      (if value then "true" else "false")
    else if lib.isInt value then
      toString value
    else if lib.isFloat value then
      builtins.toJSON value
    else if lib.isString value then
      "\"${escape value}\""
    else if lib.isList value then
      (
        if value == [ ] then
          "{}"
        else
          "{\n"
          + lib.concatMapStrings (item: "${inner}${render inner item},\n") value
          + "${indent}}"
      )
    else if lib.isAttrs value then
      let
        # Entries written before the named keys, such as a plugin name.
        positional = value.__positional or [ ];
        named = builtins.removeAttrs value [ "__positional" ];
        key = name: if identifier name then "${name} = " else "[\"${escape name}\"] = ";
      in
      (
        if positional == [ ] && named == { } then
          "{}"
        else
          "{\n"
          + lib.concatMapStrings (item: "${inner}${render inner item},\n") positional
          + lib.concatStrings (
            lib.mapAttrsToList (name: item: "${inner}${key name}${render inner item},\n") named
          )
          + "${indent}}"
      )
    else
      throw "options/cli/nvim/lua.nix: cannot render ${builtins.typeOf value}";

  # A whole plugin file: `return { <specs> }`.
  renderSpecs = specs: ''
    return ${render "" specs}
  '';
in
{
  inherit raw render renderSpecs;
}
