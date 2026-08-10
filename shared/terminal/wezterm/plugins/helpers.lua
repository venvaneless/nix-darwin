-- shared/terminal/wezterm/plugins/helpers.lua

local M = {}

function M.append_keys(config, keys)
    config.keys = config.keys or {}

    for _, key in ipairs(keys) do
        table.insert(config.keys, key)
    end
end

return M
