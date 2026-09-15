# shared/terminal/wezterm/themes/wez-nord-otto.nix
#
# =====================================================================
# WEZTERM THEME: NORD OTTO
# =====================================================================

{ ... }:
{
  config.home.shared.terminal.wezterm.themes.nord-otto = {
    name = "nord-otto";
    title = "Nord Otto";
    description = "Nord-based Otto palette with its terminal and tab bar colors.";

    # Lua file this theme is written to and loaded from.
    relativePath = ".config/wezterm/themes/nord-otto.lua";

    colorScheme = null;

    windowFrame = {
      active_titlebar_bg = "#434C5E";
      inactive_titlebar_bg = "#3B4252";
      active_titlebar_fg = "#E5E9F0";
      inactive_titlebar_fg = "#D8DEE9";
    };

    colors = {
      foreground = "#E3927A";
      background = "#2B303B";
      cursor_bg = "#FF007F";
      cursor_border = "#FF007F";
      cursor_fg = "#2B303B";
      selection_bg = "#838DA0";
      selection_fg = "#F49A4E";
      scrollbar_thumb = "#F26E65";
      split = "#434C5E";
      ansi = [ "#3B4252" "#BF616A" "#A3BE8C" "#EBCB8B" "#A0B5CA" "#D7687F" "#88C0D0" "#8CADAB" ];
      brights = [ "#4C566A" "#F0AA53" "#A3BE8C" "#EBCB8B" "#81A1C1" "#D1A0AA" "#8FBCBB" "#ECEFF4" ];

      tab_bar = {
        background = "#3B4252";
        active_tab = {
          bg_color = "#4C566A";
          fg_color = "#8FBCBB";
        };
        inactive_tab = {
          bg_color = "#434C5E";
          fg_color = "#81A1C1";
        };
        inactive_tab_hover = {
          bg_color = "#81A1C1";
          fg_color = "#F8355E";
        };
        new_tab = {
          bg_color = "#3B4252";
          fg_color = "#88C0D0";
        };
        new_tab_hover = {
          bg_color = "#88C0D0";
          fg_color = "#D7687F";
        };
      };
    };
  };
}