# WEZTERM: SAVED CATPPUCCIN THEME LOADER
# =======================================
# Kept for a possible return to Catppuccin. This module is deliberately
# not imported by the active WezTerm configuration.

{ pkgs, ... }:

let
  themesLua = pkgs.writeText "themes.lua" /* lua */ ''
    local wezterm = require("wezterm")

    local catppuccin = dofile(
        wezterm.config_dir .. "/catppuccin-config/catppuccin.lua"
    )

    local M = {}


    function M.apply(config)
        catppuccin.apply_to_config(config, {
            sync = true,

            sync_flavors = {
                light = "latte",
                dark = "macchiato",
            },

            accent = "lavender",
        })
    end


    return M
  '';
in
{
  home.file.".config/wezterm/themes.lua".source = themesLua;
}
