# shared/terminal/wezterm/personal/wez-command_palette.nix
#
# Embedded Lua source generated into .config/wezterm/personal/command_palette.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "command_palette.lua" /* lua */ ''
    -- ~/.config/wezterm/personal/command_palette.lua
    --
    -- Personal command picker. Add directory entries to `folders` below.

    local wezterm = require("wezterm")
    local act = wezterm.action

    local M = {}
    local home = os.getenv("HOME")

    -- Keep the rebuild target in one easy-to-edit place.
    local settings = {
        darwin_flake = home .. "/.config/nix/nix-config#macbook",
    }

    -- Add another folder by inserting { id = "...", label = "...", path = "..." }.
    local folders = {
        { id = "config", label = "Configuration", path = home .. "/.config" },
        { id = "nix-config", label = "Nix configuration", path = home .. "/.config/nix/nix-config" },
        { id = "downloads", label = "Downloads", path = home .. "/Downloads" },
    }

    local function cwd_to_path(uri)
        if not uri then
            return home
        end

        if type(uri) == "userdata" and uri.file_path then
            return uri:file_path()
        end

        return tostring(uri)
            :gsub("^file://[^/]*", "")
            :gsub("%%20", " ")
    end

    local function send_command(window, pane, command)
        window:perform_action(act.SendString(command .. "\n"), pane)
    end

    local function is_git_repository(cwd)
        local called, success = pcall(wezterm.run_child_process, {
            "git",
            "-C",
            cwd,
            "rev-parse",
            "--is-inside-work-tree",
        })

        return called and success
    end

    local function show_folder_picker(window, pane)
        local choices = {}

        for _, folder in ipairs(folders) do
            table.insert(choices, {
                id = folder.id,
                label = folder.label .. "  —  " .. folder.path,
            })
        end

        window:perform_action(
            act.InputSelector({
                title = "Change directory",
                choices = choices,
                fuzzy = true,
                action = wezterm.action_callback(function(inner_window, _, id)
                    if not id then
                        return
                    end

                    for _, folder in ipairs(folders) do
                        if folder.id == id then
                            -- Send cd to the current shell rather than opening a tab.
                            wezterm.time.call_after(0.15, function()
                                local active_pane = inner_window:active_pane()

                                if active_pane then
                                    send_command(
                                        inner_window,
                                        active_pane,
                                        "cd " .. wezterm.shell_quote_arg(folder.path)
                                    )
                                end
                            end)
                            break
                        end
                    end
                end),
            }),
            pane
        )
    end

    M.action = wezterm.action_callback(function(window, pane)
        local choices = {
            { id = "reload-fish", label = "Fish: Reload configuration" },
            { id = "darwin-rebuild-switch", label = "Nix: Rebuild and switch (macbook)" },
            { id = "folders", label = "Folders: Change directory" },
        }

        local cwd = cwd_to_path(pane:get_current_working_dir())

        if is_git_repository(cwd) then
            table.insert(choices, 2, {
                id = "git-add-all",
                label = "Git: Add everything (git add -A)",
            })
        end

        window:perform_action(
            act.InputSelector({
                title = "Personal commands",
                choices = choices,
                fuzzy = true,
                action = wezterm.action_callback(function(inner_window, inner_pane, id)
                    if id == "reload-fish" then
                        send_command(
                            inner_window,
                            inner_pane,
                            "source " .. wezterm.shell_quote_arg(home .. "/.config/fish/config.fish")
                        )
                    elseif id == "git-add-all" then
                        send_command(inner_window, inner_pane, "git add -A")
                    elseif id == "darwin-rebuild-switch" then
                        send_command(
                            inner_window,
                            inner_pane,
                            "sudo -H darwin-rebuild switch --flake "
                                .. wezterm.shell_quote_arg(settings.darwin_flake)
                        )
                    elseif id == "folders" then
                        wezterm.time.call_after(0.15, function()
                            local active_pane = inner_window:active_pane()

                            if active_pane then
                                show_folder_picker(inner_window, active_pane)
                            end
                        end)
                    end
                end),
            }),
            pane
        )
    end)

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/personal/command_palette.lua".source = luaConfig;
  };
}
