# shared/terminal/wezterm/themes/wez-nord.nix
#
# =====================================================================
# WEZTERM THEME: NORD
# =====================================================================

{ ... }:
{
  config.shared.terminal.wezterm.themes.nord = {
    colorScheme = null;

    windowFrame = {
      active_titlebar_bg = "#434C5E";
      inactive_titlebar_bg = "#3B4252";
      active_titlebar_fg = "#E5E9F0";
      inactive_titlebar_fg = "#D8DEE9";
    };

    colors = {
      foreground = "#E5E9F0";
      background = "#293340";
      cursor_bg = "#88C0D0";
      cursor_border = "#88C0D0";
      cursor_fg = "#2E3440";
      selection_bg = "#4C566A";
      selection_fg = "#E5E9F0";
      scrollbar_thumb = "#4C566A";
      split = "#434C5E";
      ansi = [ "#3B4252" "#BF616A" "#A3BE8C" "#EBCB8B" "#81A1C1" "#B48EAD" "#88C0D0" "#E5E9F0" ];
      brights = [ "#4C566A" "#D08770" "#A3BE8C" "#EBCB8B" "#81A1C1" "#B48EAD" "#8FBCBB" "#ECEFF4" ];

      tab_bar = {
        background = "#3B4252";
        active_tab = {
          bg_color = "#4C566A";
          fg_color = "#E5E9F0";
        };
        inactive_tab = {
          bg_color = "#434C5E";
          fg_color = "#81A1C1";
        };
        inactive_tab_hover = {
          bg_color = "#81A1C1";
          fg_color = "#2E3440";
        };
        new_tab = {
          bg_color = "#3B4252";
          fg_color = "#88C0D0";
        };
        new_tab_hover = {
          bg_color = "#88C0D0";
          fg_color = "#2E3440";
        };
      };
    };
  };
}