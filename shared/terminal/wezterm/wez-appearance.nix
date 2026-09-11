# shared/terminal/wezterm/wez-appearance.nix

{
  config,
  lib,
  ...
}:

let
  cfg = config.ven.features.terminal.wezterm;
in
{
  imports = [
    ./themes/wez-gruvbox.nix
    ./themes/wez-nord.nix
    ./themes/wez-nord-otto.nix
    ./themes/wez-otto.nix
  ];

  config = lib.mkIf cfg.enable {
    # ---- THEMES ---- #
    # The names are the Lua files imported above. Adding a theme means
    # adding its file to ./themes, importing it, and listing it here.
    #
    # ** default is what every machine uses. A machine sets its own in
    # ** its home file, and none leaves WezTerm's palette alone.
    ven.features.terminal.wezterm.themes = {
      list = [
        "gruvbox"
        "nord"
        "nord-otto"
        "otto"
      ];

      default = "gruvbox";
    };

    programs.wezterm.settings = {
      # Window
      window_close_confirmation = "NeverPrompt";
      window_decorations = "INTEGRATED_BUTTONS|RESIZE";
      window_background_opacity = 0.90;
      macos_window_background_blur = 20;

      # Startup size
      initial_cols = 95;
      initial_rows = 30;

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
    };
  };
}
