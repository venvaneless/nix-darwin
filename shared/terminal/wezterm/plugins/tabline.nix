# shared/terminal/wezterm/plugins/tabline.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/tabline.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "tabline.lua" /* lua */ ''
    -- shared/terminal/wezterm/plugins/tabline.lua

    local wezterm = require("wezterm")
    local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

    local gruvbox = {
        bg0 = "#282828",
        bg1 = "#3c3836",
        bg2 = "#504945",
        bg3 = "#665c54",
        fg0 = "#fbf1c7",
        fg1 = "#ebdbb2",
        gray = "#a89984",
        yellow = "#fabd2f",
        orange = "#fe8019",
        red = "#fb4934",
        aqua = "#8ec07c",
        blue = "#83a598",
    }

    local M = {}

    function M.apply(config)
        tabline.setup({
            options = {
                theme = "Gruvbox Dark (Gogh)",
                icons_enabled = true,
                tabs_enabled = true,

                theme_overrides = {
                    tab = {
                        active = { fg = gruvbox.bg0, bg = gruvbox.yellow },
                        inactive = { fg = gruvbox.gray, bg = gruvbox.bg1 },
                        inactive_hover = { fg = gruvbox.fg1, bg = gruvbox.bg2 },
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

                    { Foreground = { Color = gruvbox.yellow } },
                    { Background = { Color = gruvbox.bg0 } },
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
                    { Foreground = { Color = gruvbox.yellow } },
                    { Background = { Color = gruvbox.bg0 } },
                    { Text = wezterm.nerdfonts.pl_right_hard_divider },

                    { Foreground = { Color = gruvbox.bg0 } },
                    { Background = { Color = gruvbox.yellow } },

                    {
                        "hostname",
                        padding = { left = 1, right = 1 },
                    },
                },

                tabline_y = {
                    { Foreground = { Color = gruvbox.orange } },
                    { Background = { Color = gruvbox.yellow } },
                    { Text = wezterm.nerdfonts.pl_right_hard_divider },

                    { Foreground = { Color = gruvbox.bg0 } },
                    { Background = { Color = gruvbox.orange } },

                    {
                        "datetime",
                        padding = { left = 1, right = 1 },
                    },
                },

                tabline_z = {
                    { Foreground = { Color = gruvbox.bg0 } },
                    { Background = { Color = gruvbox.orange } },
                    { Text = wezterm.nerdfonts.pl_right_hard_divider },

                    { Foreground = { Color = gruvbox.yellow } },
                    { Background = { Color = gruvbox.bg0 } },

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

        config.colors = config.colors or {}
        config.colors.tab_bar = config.colors.tab_bar or {}
        config.colors.tab_bar.background = gruvbox.bg0
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/tabline.lua".source = luaConfig;
  };
}
