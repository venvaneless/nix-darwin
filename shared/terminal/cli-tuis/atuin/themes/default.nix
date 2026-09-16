# shared/terminal/cli-tuis/atuin/themes/default.nix

# =====================================================================
# ATUIN THEMES
#
# Every theme file in this folder, so adding a theme is dropping a file
# in rather than editing a list.
# =====================================================================

{ lib, ... }:

{
  imports =
    let
      themeFiles = lib.filterAttrs (
        name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
      ) (builtins.readDir ./.);
    in
    map (name: ./. + "/${name}") (lib.attrNames themeFiles);
}
