-- shared/terminal/wezterm/plugins/smart_workspace_switcher.lua

local wezterm = require("wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local M = {}

function M.apply(config)
    workspace_switcher.apply_to_config(config)
end

return M
