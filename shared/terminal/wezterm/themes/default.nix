# shared/terminal/wezterm/themes/default.nix
#
# =====================================================================
# WEZTERM: SHARED THEME KNOBS
# =====================================================================
#
# Each palette owns its values. The option helper defines the schema and
# writes only the selected palette into WezTerm's runtime Lua directory.
# =====================================================================

{ ... }:
{
  imports = [
    ./wez-gruvbox.nix
    ./wez-nord.nix
    ./wez-nord-otto.nix
    ./wez-otto.nix
  ];
}