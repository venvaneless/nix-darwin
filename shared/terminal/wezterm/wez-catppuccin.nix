# shared/terminal/wezterm/wez-catppuccin.nix
#
# =====================================================================
# WEZTERM: CATPPUCCIN TOGGLES
#
# The Catppuccin modules are kept as templates next to the active
# Gruvbox configuration. They are always deployed, but only loaded
# when a toggle below is enabled, so switching themes is a one line
# change instead of a file move.
#
# The two toggles are independent:
#
#   appearance  replaces the colour scheme, window frame and colours
#   tabline     restyles the tab bar through the tabline plugin
#
# Both default to false because the active theme is Gruvbox.
# =====================================================================

{
  lib,
  ...
}:

{
  options.ven.features.terminal.wezterm.catppuccin = {
    # ---- Appearance
    # Loads catppuccin-config/appearance.lua, which pulls in
    # themes.lua and the Catppuccin palette.
    appearance.enable =
      lib.mkEnableOption "Catppuccin appearance for WezTerm";

    # ---- Tabline
    # Loads catppuccin-config/tabline.lua, which restyles the tabline
    # plugin. Replaces the Gruvbox styling in plugins/tabline.lua.
    tabline.enable =
      lib.mkEnableOption "Catppuccin tabline styling for WezTerm";
  };
}
