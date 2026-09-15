# options/package-options/wezterm/plugins/wez-smart_workspace_switcher.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/smart_workspace_switcher.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.shared.terminal.wezterm;

  luaConfig = pkgs.writeText "smart_workspace_switcher.lua" /* lua */ ''
    -- options/package-options/wezterm/plugins/smart_workspace_switcher.lua

    local wezterm = require("wezterm")
    local workspace_switcher = wezterm.plugin.require(${builtins.toJSON cfg.plugins.smartWorkspaceSwitcher.url})

    local M = {}

    function M.apply(config)
        workspace_switcher.apply_to_config(config)
    end

    return M
  '';
in
{
  options.shared.terminal.wezterm.plugins.smartWorkspaceSwitcher.url = lib.mkOption {
    type = lib.types.str;
    description = "Git URL for the smart-workspace-switcher WezTerm plugin.";
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/smart_workspace_switcher.lua".source = luaConfig;
  };
}
