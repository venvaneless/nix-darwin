# shared/terminal/wezterm/themes/wez-gruvbox.nix
#
# Embedded Lua source generated into .config/wezterm/themes/gruvbox.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "gruvbox.lua" /* lua */ ''
    -- shared/terminal/wezterm/themes/gruvbox.lua
    --
    -- Gruvbox Dark (Gogh) with the local WezTerm colour overrides.

    local M = {}

    function M.apply(config)
        config.color_scheme = "Gruvbox Dark (Gogh)"

        -- Titlebar and command palette.
        config.integrated_title_button_color = "#d79921"
        config.command_palette_bg_color = "#282828"
        config.command_palette_fg_color = "#fabd2f"

        -- Keep fonts and sizing from wez-appearance.nix.
        config.window_frame = config.window_frame or {}
        config.window_frame.active_titlebar_bg = "#282828"
        config.window_frame.inactive_titlebar_bg = "#1d2021"
        config.window_frame.active_titlebar_fg = "#ebdbb2"
        config.window_frame.inactive_titlebar_fg = "#a89984"
        config.window_frame.button_fg = "#ebdbb2"
        config.window_frame.button_bg = "#282828"
        config.window_frame.button_hover_fg = "#282828"
        config.window_frame.button_hover_bg = "#fabd2f"

        -- Minimal Gruvbox overrides.
        config.colors = config.colors or {}
        config.colors.cursor_bg = "#fabd2f"
        config.colors.cursor_border = "#fabd2f"
        config.colors.cursor_fg = "#282828"
        config.colors.selection_fg = "#282828"
        config.colors.selection_bg = "#d79921"
        config.colors.scrollbar_thumb = "#665c54"

        config.colors.tab_bar = {
            background = "#1d2021",

            active_tab = {
                bg_color = "#282828",
                fg_color = "#fabd2f",
                intensity = "Bold",
                underline = "None",
                italic = false,
                strikethrough = false,
            },

            inactive_tab = {
                bg_color = "#3c3836",
                fg_color = "#a89984",
            },

            inactive_tab_hover = {
                bg_color = "#504945",
                fg_color = "#ebdbb2",
                italic = false,
            },

            new_tab = {
                bg_color = "#1d2021",
                fg_color = "#665c54",
            },

            new_tab_hover = {
                bg_color = "#3c3836",
                fg_color = "#fabd2f",
                italic = false,
            },
        }
    end

    return M
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.appearance.theme == "gruvbox") {
    home.file.".config/wezterm/themes/gruvbox.lua".source = luaConfig;
  };
}
