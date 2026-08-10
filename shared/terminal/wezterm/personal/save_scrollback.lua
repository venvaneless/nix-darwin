-- shared/terminal/wezterm/personal/save_scrollback.lua
--
-- Writes the visible terminal plus its retained scrollback to a file
-- in Downloads and copies the same text to the clipboard.

local wezterm = require("wezterm")

local platform = dofile(
    wezterm.config_dir .. "/personal/platform.lua"
)

local M = {}

-- Settings
local settings = {
    output_dir = os.getenv("HOME") .. "/Downloads",
    filename_format = "wezterm-scrollback-%Y-%m-%d_%H-%M-%S.txt",
    key = "S",

    -- macOS: Command + Shift + S
    -- Linux: Super + Shift + S
    --
    -- This was hardcoded to "CMD|SHIFT", which never fired on Linux.
    mods = platform.super .. "|SHIFT",
}

local function save_scrollback(window, pane)
    local dimensions = pane:get_dimensions()

    -- Get the visible terminal plus retained scrollback.
    local text = pane:get_lines_as_text(dimensions.scrollback_rows)

    local filename = os.date(settings.filename_format)
    local filepath = settings.output_dir .. "/" .. filename

    local file, open_error = io.open(filepath, "w")

    if not file then
        window:toast_notification(
            "WezTerm",
            "Failed to save scrollback:\n" .. tostring(open_error),
            nil,
            5000
        )

        return
    end

    file:write(text)
    file:close()

    -- Copy the same scrollback text to the system clipboard.
    window:copy_to_clipboard(text, "Clipboard")

    window:toast_notification(
        "WezTerm",
        "Scrollback saved to Downloads and copied to clipboard.",
        nil,
        4000
    )
end

function M.apply(config)
    config.keys = config.keys or {}

    table.insert(config.keys, {
        -- Save scrollback
        -- Writes the visible terminal plus its retained scrollback to
        -- a timestamped file in Downloads, copies the same text to the
        -- clipboard, and reports the result as a notification.
        key = settings.key,
        mods = settings.mods,
        action = wezterm.action_callback(save_scrollback),
    })
end

return M
