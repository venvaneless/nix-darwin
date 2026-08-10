local wezterm = require("wezterm")

local quick_commands_menu =
  dofile(wezterm.config_dir .. "/overlays/quick_commands/menu.lua")

wezterm.on("augment-command-palette", function(window, pane)
  return {
    {
      brief = "Quick commands",
      icon = "md_flash",
      action = wezterm.action_callback(function(window, pane)
        quick_commands_menu.show(window, pane)
      end),
    },
  }
end)
