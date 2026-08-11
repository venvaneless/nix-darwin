# shared/terminal/wezterm/overlays/quick_commands/wez-actions.nix
#
# Embedded Lua source generated into .config/wezterm/overlays/quick_commands/actions.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "actions.lua" /* lua */ ''
    local wezterm = require("wezterm")
    local act = wezterm.action

    local M = {}

    function M.cleanup_cache(window, pane)
      window:perform_action(
        act.SpawnCommandInNewTab({
          args = { "zsh", "-lc", "paru -Scc && paccache -rk1" },
        }),
        pane
      )
    end

    function M.cd_here(window, pane, folder)
      pane:send_text('cd "' .. folder .. '"\n')
    end

    function M.open_dolphin(window, pane, folder)
      window:perform_action(
        act.SpawnCommandInNewTab({
          args = { "zsh", "-lc", 'dolphin "' .. folder .. '"' },
        }),
        pane
      )
    end

    function M.new_tab_here(window, pane, folder)
      window:perform_action(
        act.SpawnCommandInNewTab({
          cwd = folder,
        }),
        pane
      )
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/overlays/quick_commands/actions.lua".source = luaConfig;
  };
}
