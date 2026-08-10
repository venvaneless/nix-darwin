-- shared/terminal/wezterm/personal/platform.lua
--
-- Runtime platform detection for the Lua modules.
--
-- The key bindings generated from Nix resolve the platform at build
-- time in wez-keybindings.nix, so they do not need this module. The
-- runtime modules below still do, because they build their bindings
-- while WezTerm is starting.

local wezterm = require("wezterm")

local M = {}

M.is_macos = wezterm.target_triple:find("darwin") ~= nil
M.is_linux = wezterm.target_triple:find("linux") ~= nil

-- Command on macOS, Super/Windows key on Linux.
M.super = M.is_macos and "CMD" or "SUPER"

-- Shared terminal modifier.
M.terminal_mod = "CTRL|SHIFT"

return M
