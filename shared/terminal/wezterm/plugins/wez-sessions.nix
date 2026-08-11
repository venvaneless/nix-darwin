# shared/terminal/wezterm/plugins/wez-sessions.nix
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
        -- shared/terminal/wezterm/plugins/sessions.lua
        
        local wezterm = require("wezterm")
        local sessions = wezterm.plugin.require("https://github.com/abidibo/wezterm-sessions")
        
        local M = {}
        
        function M.apply(config)
            sessions.apply_to_config(config, {
                auto_save_interval_s = 30,
                git_branch_warn = true,
            })
        end
        
        M.apply(config)
      end
    '';
  };
}

