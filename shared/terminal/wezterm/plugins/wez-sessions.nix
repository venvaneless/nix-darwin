# shared/terminal/wezterm/plugins/wez-sessions.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/sessions.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "sessions.lua" /* lua */ ''
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

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/sessions.lua".source = luaConfig;
  };
}
