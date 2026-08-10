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
