# shared/terminal/wezterm/themes/wez-otto.nix
#
# =====================================================================
# WEZTERM THEME: OTTO
# =====================================================================

{ ... }:
{
  config.shared.terminal.wezterm.themes.otto = {
    name = "otto";
    title = "Otto";
    description = "Otto terminal, window frame, and tab bar colors.";

    # Lua file this theme is written to and loaded from.
    relativePath = ".config/wezterm/themes/otto.lua";

    colorScheme = null;

    windowFrame = {
      active_titlebar_bg = "#344153";
      inactive_titlebar_bg = "#1E2129";
      active_titlebar_fg = "#FEFEFE";
      inactive_titlebar_fg = "#D8DEE3";
    };

    colors = {
      foreground = "#E3927A";
      background = "#2B303B";
      cursor_bg = "#F7C067";
      cursor_border = "#F8355E";
      cursor_fg = "#28333F";
      selection_bg = "#42636E";
      selection_fg = "#000000";
      scrollbar_thumb = "#F77267";
      split = "#AE2754";
      ansi = [ "#92A3BA" "#FD3762" "#2AACAA" "#F7C067" "#F77067" "#D06179" "#5CC6D1" "#9CACAD" ];
      brights = [ "#758AA8" "#FF4772" "#2EBCBB" "#FFC66A" "#FF7C77" "#CE79FF" "#60CCD8" "#FEFEFE" ];

      tab_bar = {
        background = "#344153";
        active_tab = {
          bg_color = "#374558";
          fg_color = "#F7C068";
        };
        inactive_tab = {
          bg_color = "#42536A";
          fg_color = "#F7C067";
        };
        inactive_tab_hover = {
          bg_color = "#F7C067";
          fg_color = "#28333F";
        };
        new_tab = {
          bg_color = "#344153";
          fg_color = "#5CC6D1";
        };
        new_tab_hover = {
          bg_color = "#5CC6D1";
          fg_color = "#28333F";
        };
      };
    };
  };
}