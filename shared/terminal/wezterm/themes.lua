-- shared/terminal/wezterm/themes.lua
--
-- Catppuccin theme loader.
--
-- Only used when the Catppuccin appearance toggle is enabled in
-- wez-catppuccin.nix. With the toggle off this file is deployed but
-- never loaded.

local wezterm = require("wezterm")

-- The original looked for catppuccin.lua in the configuration root,
-- where it has never existed. It lives in catppuccin-config/.
local catppuccin = dofile(
    wezterm.config_dir .. "/catppuccin-config/catppuccin.lua"
)

local M = {}

function M.apply(config)
    catppuccin.apply_to_config(config, {
        sync = true,
        sync_flavors = {
            light = 'latte',
            dark = 'macchiato',
        },
        accent = 'lavender',
    })
end

return M
