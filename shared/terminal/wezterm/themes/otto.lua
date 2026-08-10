-- shared/terminal/wezterm/themes/otto.lua

local M = {}

function M.apply(config)
    config.color_scheme = nil
    config.colors = config.colors or {}

    -- main Otto palette with requested background
    config.colors.foreground = "#E3927A"
    config.colors.background = "#2B303B"

    config.colors.cursor_bg = "#F7C067"
    config.colors.cursor_border = "#F8355E"
    config.colors.cursor_fg = "#28333F"

    config.colors.selection_bg = "#42636E"
    config.colors.selection_fg = "#000000"

    config.colors.scrollbar_thumb = "#F77267"
    config.colors.split = "#AE2754"

    config.colors.ansi = {
        "#92A3BA", -- black slot, Otto blue
        "#FD3762", -- red
        "#2AACAA", -- green/teal
        "#F7C067", -- yellow/orange
        "#F77067", -- blue slot repurposed to Otto coral
        "#D06179", -- magenta
        "#5CC6D1", -- cyan
        "#9CACAD", -- white/muted
    }

    config.colors.brights = {
        "#758AA8", -- bright black
        "#FF4772", -- bright red
        "#2EBCBB", -- bright green
        "#FFC66A", -- bright yellow/orange
        "#FF7C77", -- bright coral
        "#CE79FF", -- bright magenta
        "#60CCD8", -- bright cyan
        "#FEFEFE", -- bright white
    }

    config.window_frame = {
        active_titlebar_bg = "#344153",
        inactive_titlebar_bg = "#1E2129",
        active_titlebar_fg = "#FEFEFE",
        inactive_titlebar_fg = "#D8DEE3",
    }

    config.colors.tab_bar = {
        background = "#344153",

        active_tab = {
            bg_color = "#374558",
            fg_color = "#F7C068",
        },

        inactive_tab = {
            bg_color = "#42536A",
            fg_color = "#F7C067",
        },

        inactive_tab_hover = {
            bg_color = "#F7C067",
            fg_color = "#28333F",
        },

        new_tab = {
            bg_color = "#344153",
            fg_color = "#5CC6D1",
        },

        new_tab_hover = {
            bg_color = "#5CC6D1",
            fg_color = "#28333F",
        },
    }

    -- window translucency: whole window/background
    config.window_background_opacity = 0.90
    -- cell backgrounds (selection, colored blocks, etc.)
    config.text_background_opacity = 1.0
end

return M
