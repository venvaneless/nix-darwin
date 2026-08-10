-- shared/terminal/wezterm/plugins/plugins.lua

local wezterm = require("wezterm")

local M = {}

local plugin_modules = {
    "resurrect",
    "smart_workspace_switcher",
    "sessions",
    "tabline",
}

function M.apply(config)
    wezterm.log_info("plugins.apply() called")

    for _, plugin_name in ipairs(plugin_modules) do
        wezterm.log_info("Loading plugin module: " .. plugin_name)

        local ok, plugin = pcall(dofile, wezterm.config_dir .. "/plugins/" .. plugin_name .. ".lua")

        if ok and plugin and type(plugin.apply) == "function" then
            wezterm.log_info("Applying plugin module: " .. plugin_name)
            local ok_apply, err = pcall(plugin.apply, config)
            if ok_apply then
                wezterm.log_info("Applied plugin module: " .. plugin_name)
            else
                wezterm.log_error("Failed while applying plugin " .. plugin_name .. ": " .. tostring(err))
            end
        else
            wezterm.log_error("Failed to load plugin module: " .. plugin_name .. " :: " .. tostring(plugin))
        end
    end
end

return M
