# shared/terminal/wezterm/personal/wez-nvim_chrome.nix
#
# Embedded Lua source generated into .config/wezterm/personal/nvim_chrome.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "nvim_chrome.lua" /* lua */ ''
    -- shared/terminal/wezterm/personal/nvim_chrome.lua
    --
    -- Hides WezTerm's tab bar only while the active local pane runs
    -- Neovim. Normal shell and terminal sessions retain their tabline.

    local wezterm = require("wezterm")

    local M = {}

    local function is_neovim(pane)
        local process_name = pane:get_foreground_process_name()

        return process_name and process_name:match("/nvim$") ~= nil
    end

    function M.apply(config)
        wezterm.on("update-status", function(window, pane)
            local overrides = window:get_config_overrides() or {}
            local enable_tab_bar = not is_neovim(pane)

            -- Avoid reloading the window configuration when the process did
            -- not actually change between two status updates.
            if overrides.enable_tab_bar ~= enable_tab_bar then
                overrides.enable_tab_bar = enable_tab_bar
                window:set_config_overrides(overrides)
            end
        end)
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/personal/nvim_chrome.lua".source = luaConfig;
  };
}
