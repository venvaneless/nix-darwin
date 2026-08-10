-- shared/terminal/wezterm/themes/nord.lua

-- /home/ven/.config/terminal/wezterm/themes/nord.lua

local M = {}

function M.apply(config)
    config.color_scheme = nil

    config.colors = config.colors or {}

    -- main terminal palette
    config.colors.foreground = "#E5E9F0"
    config.colors.background = "#293340"

    config.colors.cursor_bg = "#88C0D0"
    config.colors.cursor_border = "#88C0D0"
    config.colors.cursor_fg = "#2E3440"

    config.colors.selection_bg = "#4C566A"
    config.colors.selection_fg = "#E5E9F0"

    config.colors.scrollbar_thumb = "#4C566A"
    config.colors.split = "#434C5E"

    config.colors.ansi = {
        "#3B4252", -- black
        "#BF616A", -- red
        "#A3BE8C", -- green
        "#EBCB8B", -- yellow
        "#81A1C1", -- blue
        "#B48EAD", -- magenta
        "#88C0D0", -- cyan
        "#E5E9F0", -- white
    }

    config.colors.brights = {
        "#4C566A", -- bright black
        "#D08770", -- bright red/orange
        "#A3BE8C", -- bright green
        "#EBCB8B", -- bright yellow
        "#81A1C1", -- bright blue
        "#B48EAD", -- bright magenta
        "#8FBCBB", -- bright cyan
        "#ECEFF4", -- bright white
    }

    config.window_frame = {
        active_titlebar_bg = "#434C5E",
        inactive_titlebar_bg = "#3B4252",
        active_titlebar_fg = "#E5E9F0",
        inactive_titlebar_fg = "#D8DEE9",
    }

    config.colors.tab_bar = {
        background = "#3B4252",

        active_tab = {
            bg_color = "#4C566A",
            fg_color = "#E5E9F0",
        },

        inactive_tab = {
            bg_color = "#434C5E",
            fg_color = "#81A1C1",
        },

        inactive_tab_hover = {
            bg_color = "#81A1C1",
            fg_color = "#2E3440",
        },

        new_tab = {
            bg_color = "#3B4252",
            fg_color = "#88C0D0",
        },

        new_tab_hover = {
            bg_color = "#88C0D0",
            fg_color = "#2E3440",
        },
    }
end

return M
