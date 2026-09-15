# shared/terminal/wezterm/themes/wez-gruvbox.nix
#
# =====================================================================
# WEZTERM THEME: GRUVBOX
# =====================================================================

{ ... }:
{
  config.shared.terminal.wezterm.themes.gruvbox = {
    colorScheme = "Gruvbox Dark (Gogh)";
    titleButtonColor = "#d79921";

    commandPalette = {
      background = "#282828";
      foreground = "#fabd2f";
    };

    windowFrame = {
      active_titlebar_bg = "#282828";
      inactive_titlebar_bg = "#1d2021";
      active_titlebar_fg = "#ebdbb2";
      inactive_titlebar_fg = "#a89984";
      button_fg = "#ebdbb2";
      button_bg = "#282828";
      button_hover_fg = "#282828";
      button_hover_bg = "#fabd2f";
    };

    colors = {
      cursor_bg = "#fabd2f";
      cursor_border = "#fabd2f";
      cursor_fg = "#282828";
      selection_fg = "#282828";
      selection_bg = "#d79921";
      scrollbar_thumb = "#665c54";

      tab_bar = {
        background = "#1d2021";
        active_tab = {
          bg_color = "#282828";
          fg_color = "#fabd2f";
          intensity = "Bold";
          underline = "None";
          italic = false;
          strikethrough = false;
        };
        inactive_tab = {
          bg_color = "#3c3836";
          fg_color = "#a89984";
        };
        inactive_tab_hover = {
          bg_color = "#504945";
          fg_color = "#ebdbb2";
          italic = false;
        };
        new_tab = {
          bg_color = "#1d2021";
          fg_color = "#665c54";
        };
        new_tab_hover = {
          bg_color = "#3c3836";
          fg_color = "#fabd2f";
          italic = false;
        };
      };
    };
  };
}
