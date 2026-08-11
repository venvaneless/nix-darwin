# shared/terminal/wezterm/overlays/quick_commands/wez-folders.nix
#
# Embedded Lua source generated into .config/wezterm/overlays/quick_commands/folders.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "folders.lua" /* lua */ ''
    local wezterm = require("wezterm")
    local act = wezterm.action

    local actions =
      dofile(wezterm.config_dir .. "/overlays/quick_commands/actions.lua")

    local M = {}

    local function home_subdirs()
      local dirs = {}
      local home = os.getenv("HOME")

      local p = io.popen(
        'find "' .. home .. '" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort'
      )

      if not p then
        return dirs
      end

      for line in p:lines() do
        local label = line:gsub("^" .. home, "~")
        table.insert(dirs, {
          id = line,
          label = label,
        })
      end

      p:close()
      return dirs
    end

    function M.show_folder_picker(window, pane)
      window:perform_action(
        act.InputSelector({
          title = "Open folder",
          description = "Choose a folder in home",
          fuzzy = true,
          choices = home_subdirs(),
          action = wezterm.action_callback(function(window, pane, folder, label)
            if not folder then
              return
            end

            window:perform_action(
              act.InputSelector({
                title = "Folder action",
                description = folder,
                choices = {
                  { id = "cd_here", label = "CD in current pane" },
                  { id = "open_dolphin", label = "Open in Dolphin" },
                  { id = "new_tab_here", label = "Open new tab here" },
                },
                action = wezterm.action_callback(function(window, pane, action_id, _)
                  if not action_id then
                    return
                  end

                  if action_id == "cd_here" then
                    actions.cd_here(window, pane, folder)
                  elseif action_id == "open_dolphin" then
                    actions.open_dolphin(window, pane, folder)
                  elseif action_id == "new_tab_here" then
                    actions.new_tab_here(window, pane, folder)
                  end
                end),
              }),
              pane
            )
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
    home.file.".config/wezterm/overlays/quick_commands/folders.lua".source = luaConfig;
  };
}
