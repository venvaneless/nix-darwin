-- /home/ven/.config/terminal/wezterm/appearance.lua

local wezterm = require("wezterm")
local ok, themes = pcall(dofile, wezterm.config_dir .. "/themes.lua")

local M = {}

function M.apply(config)
    if ok and themes and themes.apply then
        themes.apply(config)
    end

    -- Theme
    config.color_scheme = "Rosé Pine (Gogh)"

    -- Window
    config.window_close_confirmation = "NeverPrompt"
    config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
    config.window_background_opacity = 0.90
    config.macos_window_background_blur = 20
    config.initial_cols = 120
    config.initial_rows = 25

    -- Padding
    config.window_padding = {
        left = "1cell",
        right = "1cell",
        top = "1.2cell",
        bottom = "0.6cell",
    }

    -- Font
    config.font = wezterm.font("JetBrainsMono Nerd Font")
    config.font_size = 13.0
    config.line_height = 1.5

    -- Cursor
    config.default_cursor_style = "SteadyBar"
    config.cursor_thickness = "1pt"
    config.cursor_blink_rate = 800
    config.force_reverse_video_cursor = false
    config.animation_fps = 80

    -- Titlebar
    config.integrated_title_button_alignment = "Left"
    config.integrated_title_button_color = "#B4637A"
    config.integrated_title_buttons = { "Hide", "Maximize", "Close" }

    config.window_frame = {
        font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Bold" }),
        font_size = 13.0,
        active_titlebar_bg = "#B4637A",
        inactive_titlebar_bg = "#B4637A",
        active_titlebar_fg = "#181926",
        inactive_titlebar_fg = "#181926",
        button_fg = "#181926",
        button_bg = "#B4637A",
        button_hover_fg = "#ECEFF4",
        button_hover_bg = "#D7827E",
    }

    -- Tab bar
    config.enable_tab_bar = true
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = true
    config.hide_tab_bar_if_only_one_tab = false
    config.show_new_tab_button_in_tab_bar = false
    config.show_tab_index_in_tab_bar = false
    config.tab_max_width = 28

    -- Scrollbar
    config.enable_scroll_bar = true

    -- Background image
    config.background = {
        {
            source = {
                File = "/Users/ven/iCloudDocs/multimedia-library/pictures /wallpapers/wallpaper_sets/catppuccin_wallpapers/catppuccin_waves_wallpapers/catppuccin-waves_catppuccin-apus_color_waves.png",
            },
            attachment = "Fixed",
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            horizontal_align = "Center",
            vertical_align = "Middle",
            width = "Cover",
            height = "Cover",
            opacity = 0.77,
        },
        {
            source = {
                Color = "#11111b",
            },
            width = "100%",
            height = "100%",
            opacity = 0.10,
        },
    }

    -- Command palette
    config.command_palette_bg_color = "#191724"
    config.command_palette_fg_color = "#eb6f92"

    -- Colors
    config.colors = config.colors or {}

    config.colors.cursor_bg = "#393552"
    config.colors.cursor_border = "#D7827E"
    config.colors.cursor_fg = "#D7827E"

    config.colors.selection_fg = "#b563a3"
    config.colors.selection_bg = "#232136"

    config.colors.scrollbar_thumb = "#393552"

    config.colors.tab_bar = {
        background = "#1e2030",

        active_tab = {
            bg_color = "#1e1e2e",
            fg_color = "#B4637A",
            intensity = "Bold",
            underline = "None",
            italic = false,
            strikethrough = false,
        },

        inactive_tab = {
            bg_color = "#393552",
            fg_color = "#C4A7E7",
        },

        inactive_tab_hover = {
            bg_color = "#D7827E",
            fg_color = "#313244",
            italic = false,
        },

        new_tab = {
            bg_color = "#1e1e2e",
            fg_color = "#393552",
        },

        new_tab_hover = {
            bg_color = "#393552",
            fg_color = "#D7827E",
            italic = false,
        },
    }
end

return M