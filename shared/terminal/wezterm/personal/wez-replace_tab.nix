# shared/terminal/wezterm/personal/wez-replace_tab.nix
#
# Embedded Lua source generated into .config/wezterm/personal/replace_tab.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "replace_tab.lua" /* lua */ ''
    -- shared/terminal/wezterm/personal/replace_tab.lua
    --
    -- Replaces the current tab with a fresh one that keeps its working
    -- directory, domain, workspace and title.

    local wezterm = require("wezterm")
    local act = wezterm.action

    local platform = dofile(
        wezterm.config_dir .. "/personal/platform.lua"
    )

    local M = {}

    local function replace_tab(window, pane)
        local mux_window = window:mux_window()
        local original_tab = pane:tab()

        -- Preserve the active pane's context.
        local cwd = pane:get_current_working_dir()
        local domain_name = pane:get_domain_name()
        local tab_title = original_tab:get_title()
        local workspace = window:active_workspace()

        -- Open the replacement first so that replacing the only tab
        -- does not close the entire window.
        local new_tab, new_pane = mux_window:spawn_tab({
            cwd = cwd,
            domain = {
                DomainName = domain_name,
            },
        })

        -- A tab spawned in the same mux window remains in that window's
        -- active workspace. Keep this captured for clarity and validation.
        if mux_window:get_workspace() ~= workspace then
            mux_window:set_workspace(workspace)
        end

        -- Preserve a manually assigned tab title.
        if tab_title and tab_title ~= "" then
            new_tab:set_title(tab_title)
        end

        -- Activate the replacement before closing the original tab.
        new_pane:activate()

        window:perform_action(
            act.CloseCurrentTab({
                confirm = false,
            }),
            pane
        )
    end

    function M.apply(config)
        config.keys = config.keys or {}

        table.insert(config.keys, {
            -- Replace tab
            -- Opens a fresh tab that inherits the working directory,
            -- domain, workspace and title of the current one, then closes
            -- the original.
            --
            -- macOS: Command + Shift + T
            -- Linux: Super + Shift + T
            key = "T",
            mods = platform.super .. "|SHIFT",
            action = wezterm.action_callback(replace_tab),
        })
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/personal/replace_tab.lua".source = luaConfig;
  };
}
