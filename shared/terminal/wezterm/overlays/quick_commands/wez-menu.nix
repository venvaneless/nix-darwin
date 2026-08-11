# shared/terminal/wezterm/overlays/quick_commands/wez-menu.nix
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
        package.preload["ven.wezterm.quick_commands.menu"] = function()
          local wezterm = require("wezterm")
          local act = wezterm.action
          
          local actions =
            require("ven.wezterm.quick_commands.actions")
          local folders =
            require("ven.wezterm.quick_commands.folders")
          
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
        end
      end
    '';
  };
}

