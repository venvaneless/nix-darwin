# shared/terminal/wezterm/plugins/wez-smart_workspace_switcher.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/smart_workspace_switcher.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "smart_workspace_switcher.lua" /* lua */ ''
    -- shared/terminal/wezterm/plugins/smart_workspace_switcher.lua

    local wezterm = require("wezterm")
    local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

    local M = {}

    function M.apply(config)
        workspace_switcher.apply_to_config(config)
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/smart_workspace_switcher.lua".source = luaConfig;
  };
}
