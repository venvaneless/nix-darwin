# shared/terminal/wezterm/plugins/wez-smart_workspace_switcher.nix
#
# Embedded Lua configuration for WezTerm.

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.wezterm;
in
{
  config = lib.mkIf cfg.enable {
    programs.wezterm.extraConfig = lib.mkAfter /* lua */ ''
      do
        -- shared/terminal/wezterm/plugins/smart_workspace_switcher.lua
        
        local wezterm = require("wezterm")
        local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
        
        local M = {}
        
        function M.apply(config)
            workspace_switcher.apply_to_config(config)
        end
        
        M.apply(config)
      end
    '';
  };
}

