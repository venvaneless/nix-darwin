# shared/terminal/wezterm/themes/wez-nord-otto.nix
#
# Embedded Lua source generated into .config/wezterm/themes/nord-otto.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "nord-otto.lua" /* lua */ ''
    -- shared/terminal/wezterm/themes/nord-otto.lua

    -- /home/ven/.config/terminal/wezterm/themes/nord.lua

    local M = {}

    function M.apply(config)
        config.color_scheme = nil

        config.colors = config.colors or {}

        -- main terminal palette
        config.colors.foreground = "#E3927A"
        config.colors.background = "#2B303B"

        config.colors.cursor_bg = "#FF007F"
        config.colors.cursor_border = "#FF007F"
        config.colors.cursor_fg = "#2B303B"

        config.colors.selection_bg = "#838DA0"
        config.colors.selection_fg = "#F49A4E"

        config.colors.scrollbar_thumb = "#F26E65"
        config.colors.split = "#434C5E"

        config.colors.ansi = {
            "#3B4252", -- black
            "#BF616A", -- red
            "#A3BE8C", -- green
            "#EBCB8B", -- yellow
            "#A0B5CA", -- blue
            "#D7687F", -- magenta
            "#88C0D0", -- cyan
            "#8CADAB", -- white
        }

        config.colors.brights = {
            "#4C566A", -- bright black
            "#F0AA53", -- bright red/orange
            "#A3BE8C", -- bright green
            "#EBCB8B", -- bright yellow
            "#81A1C1", -- bright blue
            "#D1A0AA", -- bright magenta
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
                fg_color = "#8FBCBB",
            },

            inactive_tab = {
                bg_color = "#434C5E",
                fg_color = "#81A1C1",
            },

            inactive_tab_hover = {
                bg_color = "#81A1C1",
                fg_color = "#F8355E",
            },

            new_tab = {
                bg_color = "#3B4252",
                fg_color = "#88C0D0",
            },

            new_tab_hover = {
                bg_color = "#88C0D0",
                fg_color = "#D7687F",
            },
        }
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.themes.nordOtto.enable {
    home.file.".config/wezterm/themes/nord-otto.lua".source = luaConfig;
  };
}
