local wezterm = require("wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local M = {}

function M.apply(config)
    tabline.setup({
        options = {
            theme = 'Nord (Gogh)',
            icons_enabled = true,
            tabs_enabled = true,

            theme_overrides = {
                tab = {
                    active = { fg = "#2B303B", bg = "#F77067" },
                    inactive = { fg = "#81A1C1", bg = "#2B303B" },
                    inactive_hover = { fg = "#F8355E", bg = "#81A1C1" },
                },
            },


            section_separators = {
                left = "",
                right = "",
            },
            component_separators = {
                left = "",
                right = "",
            },
            tab_separators = {
                left = "",
                right = "",
            },
        },

        sections = {
            tabline_a = {},
            tabline_b = {},
            tabline_c = {},

            tab_active = {
                {
                    "cwd",
                    padding = { left = 1, right = 1 },
                    max_length = 23,
                },
                {
                    "process",
                    padding = { left = 1, right = 1 },
                    process_to_icon = {
                        ["docker"] = wezterm.nerdfonts.md_docker,
                        ["git"] = wezterm.nerdfonts.dev_git,
                        ["nix"] = wezterm.nerdfonts.linux_nixos,

                        ["zsh"] = wezterm.nerdfonts.dev_terminal,
                        ["bash"] = wezterm.nerdfonts.cod_terminal_bash,
                        ["fish"] = wezterm.nerdfonts.md_fish,

                        ["node"] = wezterm.nerdfonts.md_nodejs,
                        ["javascript"] = wezterm.nerdfonts.dev_javascript,
                        ["typescript"] = wezterm.nerdfonts.dev_typescript,

                        ["python"] = wezterm.nerdfonts.dev_python,
                        ["go"] = wezterm.nerdfonts.md_language_go,

                        ["html"] = wezterm.nerdfonts.dev_html5,
                        ["css"] = wezterm.nerdfonts.dev_css3,
                        ["scss"] = wezterm.nerdfonts.dev_sass,

                        ["vue"] = wezterm.nerdfonts.dev_vuejs,
                        ["angular"] = wezterm.nerdfonts.dev_angular,

                        ["default"] = wezterm.nerdfonts.md_application,
                    },
                  },

                  { Foreground = { Color = "#F77067" } },
                  { Background = { Color = "#6982A1" } },
                  { Text = wezterm.nerdfonts.pl_left_hard_divider },
            },

            tab_inactive = {
                {
                    "cwd",
                    padding = { left = 1, right = 1 },
                    max_length = 23,
                },
            },

tabline_x = {
    { Foreground = { Color = "#F77067" } },
    { Background = { Color = "#6982A1" } },
    { Text = wezterm.nerdfonts.pl_right_hard_divider },

    { Foreground = { Color = "#ECEFF4" } },
    { Background = { Color = "#F77067" } },

    {
        "hostname",
        padding = { left = 1, right = 1 },
    },
},

tabline_y = {
    { Foreground = { Color = "#F8A488" } },
    { Background = { Color = "#F77067" } },
    { Text = wezterm.nerdfonts.pl_right_hard_divider },

    { Foreground = { Color = "#ECEFF4" } },
    { Background = { Color = "#F8A488" } },

    {
        "datetime",
        padding = { left = 1, right = 1 },
    },
},

tabline_z = {
    { Foreground = { Color = "#2B303B" } },
    { Background = { Color = "#F8A488" } },
    { Text = wezterm.nerdfonts.pl_right_hard_divider },

    { Foreground = { Color = "#F77067" } },
    { Background = { Color = "#2B303B" } },

    {
        "battery",
        padding = { left = 1, right = 1 },
    },
},
        },

        extensions = {},
    })

    config.enable_tab_bar = true
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = true
    config.tab_max_width = 28
   	config.colors.tab_bar.background = "#6982A1"
end

return M
