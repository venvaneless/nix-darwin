-- shared/terminal/wezterm/plugins/resurrect.lua
--
-- Saves and restores workspace, window and tab state.
--
-- The previous version of this file never ran: it had no `return M`,
-- so the loader in plugins.lua rejected it, and it assigned to a
-- global `config` at file scope which is nil there. The bindings
-- below are the ones it intended to define.
--
-- Keys are appended through helpers.append_keys so that the bindings
-- generated from Nix in wez-keybindings.nix are preserved instead of
-- being overwritten.

local wezterm = require("wezterm")

local resurrect = wezterm.plugin.require(
    "https://github.com/MLFlexer/resurrect.wezterm"
)

local helpers = dofile(wezterm.config_dir .. "/plugins/helpers.lua")

local M = {}

function M.apply(config)
    helpers.append_keys(config, {
        {
            -- Save workspace
            -- Writes the layout of the current workspace, with all of
            -- its windows, tabs and panes, to the resurrect state
            -- directory.
            key = "w",
            mods = "ALT",
            action = wezterm.action_callback(function(win, pane)
                resurrect.state_manager.save_state(
                    resurrect.workspace_state.get_workspace_state()
                )
            end),
        },

        {
            -- Save window
            -- Writes only the active window and its tabs to the
            -- resurrect state directory.
            key = "W",
            mods = "ALT",
            action = resurrect.window_state.save_window_action(),
        },

        {
            -- Save tab
            -- Writes only the active tab and its panes to the
            -- resurrect state directory.
            key = "T",
            mods = "ALT",
            action = resurrect.tab_state.save_tab_action(),
        },

        {
            -- Save workspace and window
            -- Runs both saves in one step, for when the whole session
            -- should be captured at once.
            --
            -- ALT+s is registered by wezterm-sessions, which loads
            -- after this module and would win, so this uses ALT+S.
            key = "S",
            mods = "ALT",
            action = wezterm.action_callback(function(win, pane)
                resurrect.state_manager.save_state(
                    resurrect.workspace_state.get_workspace_state()
                )

                win:perform_action(
                    resurrect.window_state.save_window_action(),
                    pane
                )
            end),
        },

        {
            -- Restore saved state
            -- Opens a fuzzy picker over every saved workspace, window
            -- and tab, and restores the chosen one in place.
            --
            -- ALT+r is registered by wezterm-sessions, which loads
            -- after this module and would win, so this uses ALT+R.
            key = "R",
            mods = "ALT",
            action = wezterm.action_callback(function(win, pane)
                resurrect.fuzzy_loader.fuzzy_load(
                    win,
                    pane,
                    function(id, label)
                        -- match before '/'
                        local type = string.match(id, "^([^/]+)")

                        -- match after '/'
                        id = string.match(id, "([^/]+)$")

                        -- remove file extension
                        id = string.match(id, "(.+)%..+$")

                        local opts = {
                            relative = true,
                            restore_text = true,
                            on_pane_restore =
                                resurrect.tab_state.default_on_pane_restore,
                        }

                        if type == "workspace" then
                            local state = resurrect.state_manager.load_state(
                                id,
                                "workspace"
                            )

                            resurrect.workspace_state.restore_workspace(
                                state,
                                opts
                            )
                        elseif type == "window" then
                            local state = resurrect.state_manager.load_state(
                                id,
                                "window"
                            )

                            resurrect.window_state.restore_window(
                                pane:window(),
                                state,
                                opts
                            )
                        elseif type == "tab" then
                            local state = resurrect.state_manager.load_state(
                                id,
                                "tab"
                            )

                            resurrect.tab_state.restore_tab(
                                pane:tab(),
                                state,
                                opts
                            )
                        end
                    end
                )
            end),
        },
    })
end

return M
