# shared/terminal/wezterm/overlays/quick_commands/wez-menu.nix
#
# Embedded Lua source generated into .config/wezterm/overlays/quick_commands/menu.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "menu.lua" /* lua */ ''
    local wezterm = require("wezterm")
    local act = wezterm.action

    local actions =
      dofile(wezterm.config_dir .. "/overlays/quick_commands/actions.lua")
    local folders =
      dofile(wezterm.config_dir .. "/overlays/quick_commands/folders.lua")

    local M = {}

    function M.show(window, pane)
      window:perform_action(
        act.InputSelector({
          title = "Quick commands",
          description = "Pick a command",
          fuzzy = true,
          choices = {
            { id = "cleanup_cache", label = "Cleanup cache" },
            { id = "open_folder", label = "Open folder" },
          },
          action = wezterm.action_callback(function(window, pane, id, label)
            if not id then
              return
            end

            if id == "cleanup_cache" then
              actions.cleanup_cache(window, pane)
            elseif id == "open_folder" then
              folders.show_folder_picker(window, pane)
            end
          end),
        }),
        pane
      )
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/overlays/quick_commands/menu.lua".source = luaConfig;
  };
}
