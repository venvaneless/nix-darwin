# options/package-options/wezterm/plugins/wez-sessions.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/sessions.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.home.shared.terminal.wezterm;

  luaConfig = pkgs.writeText "sessions.lua" /* lua */ ''
    -- options/package-options/wezterm/plugins/sessions.lua

    local wezterm = require("wezterm")
    local sessions = wezterm.plugin.require(${builtins.toJSON cfg.plugins.sessions.url})

    local M = {}

    function M.apply(config)
        sessions.apply_to_config(config, {
            auto_save_interval_s = ${toString cfg.plugins.sessions.autoSaveIntervalSeconds},
            git_branch_warn = ${if cfg.plugins.sessions.gitBranchWarn then "true" else "false"},
        })
    end

    return M
  '';
in
{
  options.home.shared.terminal.wezterm.plugins.sessions = {
    url = lib.mkOption {
      type = lib.types.str;
      description = "Git URL for the wezterm-sessions plugin.";
    };

    autoSaveIntervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Seconds between automatic session saves.";
    };

    gitBranchWarn = lib.mkOption {
      type = lib.types.bool;
      description = "Warn when restoring a session from a different Git branch.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/sessions.lua".source = luaConfig;
  };
}
