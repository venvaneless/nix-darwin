# shared/terminal/wezterm/wez-appearance.nix

{ lib, ... }:

{
  # Theme
  color_scheme = "Gruvbox Dark (Gogh)";

  # Window
  window_close_confirmation = "NeverPrompt";
  window_decorations = "INTEGRATED_BUTTONS|RESIZE";
  window_background_opacity = 0.90;
  macos_window_background_blur = 20;

  # Startup size
  initial_cols = 140;
  initial_rows = 38;

  # Padding
  window_padding = {
    left = "1cell";
    right = "1cell";
    top = "1.2cell";
    bottom = "0.6cell";
  };

  # Font
  font = lib.generators.mkLuaInline ''
    wezterm.font("JetBrainsMono Nerd Font")
  '';

  font_size = 13.0;
  line_height = 1.5;

  # Cursor
  default_cursor_style = "SteadyBar";
  cursor_thickness = "1pt";
  cursor_blink_rate = 800;
  force_reverse_video_cursor = false;
  animation_fps = 80;

  # Titlebar
  integrated_title_button_alignment = "Left";
  integrated_title_button_color = "#d79921";

  integrated_title_buttons = [
    "Hide"
    "Maximize"
    "Close"
  ];

  window_frame = {
    font = lib.generators.mkLuaInline ''
      wezterm.font({
          family = "JetBrainsMono Nerd Font",
          weight = "Bold",
      })
    '';

    font_size = 13.0;
    active_titlebar_bg = "#282828";
    inactive_titlebar_bg = "#1d2021";
    active_titlebar_fg = "#ebdbb2";
    inactive_titlebar_fg = "#a89984";
    button_fg = "#ebdbb2";
    button_bg = "#282828";
    button_hover_fg = "#282828";
    button_hover_bg = "#fabd2f";
  };

  # Tab bar
  enable_tab_bar = true;
  use_fancy_tab_bar = false;
  tab_bar_at_bottom = true;
  hide_tab_bar_if_only_one_tab = false;
  show_new_tab_button_in_tab_bar = false;
  show_tab_index_in_tab_bar = false;
  tab_max_width = 28;

  # Scrollbar
  enable_scroll_bar = true;

  # Command palette
  command_palette_bg_color = "#282828";
  command_palette_fg_color = "#fabd2f";

  # Minimal Gruvbox overrides
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
}