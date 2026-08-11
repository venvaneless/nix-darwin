# shared/terminal/wezterm/personal/wez-context_palette.nix
#
# Embedded Lua configuration for WezTerm.

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.wezterm;
in
{
  config = lib.mkIf cfg.enable {
    programs.wezterm.extraConfig = lib.mkAfter /* lua */ ''
      do
        -- ~/.config/wezterm/personal/context_palette.lua
        --
        -- Adds context-aware entries to WezTerm's native command palette.
        -- The list is rebuilt every time the palette opens, using the active pane's
        -- current working directory.
        
        local wezterm = require("wezterm")
        local act = wezterm.action
        
        local platform = require("ven.wezterm.personal.platform")
        
        local M = {}
        local home = os.getenv("HOME") or wezterm.home_dir
        
        -- USER SETTINGS
        -- =====================================================================
        local settings = {
            palette_rows = 24,
            parent_search_depth = 20,
        
            -- Used for nix-darwin actions.
            darwin_host = "macbook",
        
            -- First existing path wins.
            paths = {
                nix_config = home .. "/.config/nix/nix-config",
                downloads = home .. "/Downloads",
                config = home .. "/.config",
                hammerspoon = home .. "/.config/.hammerspoon",
        
                projects = {
                    home .. "/iCloudDocs/Documents/programming",
                    home .. "/Projects",
                    home .. "/Documents/programming",
                },
        
                fish_configs = {
                    home .. "/.config/fish/config.fish",
                    home .. "/.config/terminal/fish/config-ven.fish",
                },
        
                fish_functions = {
                    home .. "/.config/fish/functions",
                    home .. "/.config/terminal/fish/functions",
                },
            },
        }
        
        -- PATH HELPERS
        -- =====================================================================
        local function trim(value)
            return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
        
        local function decode_url(value)
            return value:gsub("%%(%x%x)", function(hex)
                return string.char(tonumber(hex, 16))
            end)
        end
        
        local function cwd_to_path(uri)
            if not uri then
                return home
            end
        
            if type(uri) == "userdata" and uri.file_path then
                return uri:file_path()
            end
        
            return decode_url(
                tostring(uri):gsub("^file://[^/]*", "")
            )
        end
        
        local function dirname(path)
            local normalized = path:gsub("/+$", "")
        
            if normalized == "" or normalized == "/" then
                return "/"
            end
        
            local parent = normalized:match("^(.*)/[^/]+$")
        
            if not parent or parent == "" then
                return "/"
            end
        
            return parent
        end
        
        local function basename(path)
            local normalized = path:gsub("/+$", "")
            return normalized:match("([^/]+)$") or normalized
        end
        
        local function escape_pattern(value)
            return value:gsub("([^%w])", "%%%1")
        end
        
        local function display_path(path)
            if path == home then
                return "~"
            end
        
            return path:gsub("^" .. escape_pattern(home), "~")
        end
        
        local function file_exists(path)
            local file = io.open(path, "rb")
        
            if not file then
                return false
            end
        
            file:close()
            return true
        end
        
        local function directory_exists(path)
            local ok = pcall(wezterm.read_dir, path)
            return ok
        end
        
        local function first_existing_file(paths)
            for _, path in ipairs(paths) do
                if file_exists(path) then
                    return path
                end
            end
        
            return nil
        end
        
        local function first_existing_directory(paths)
            for _, path in ipairs(paths) do
                if directory_exists(path) then
                    return path
                end
            end
        
            return nil
        end
        
        local function path_is_inside(path, root)
            return path == root
                or path:sub(1, #root + 1) == root .. "/"
        end
        
        local function find_up(start_path, markers)
            local current = start_path
        
            for _ = 1, settings.parent_search_depth do
                for _, marker in ipairs(markers) do
                    if file_exists(current .. "/" .. marker) then
                        return current, marker
                    end
                end
        
                local parent = dirname(current)
        
                if parent == current then
                    break
                end
        
                current = parent
            end
        
            return nil, nil
        end
        
        local function run_child(args)
            local called, success, stdout = pcall(
                wezterm.run_child_process,
                args
            )
        
            if not called or not success then
                return nil
            end
        
            local output = trim(stdout)
            return output ~= "" and output or nil
        end
        
        local function git_root(cwd)
            return run_child({
                "git",
                "-C",
                cwd,
                "rev-parse",
                "--show-toplevel",
            })
        end
        
        local function read_json(path)
            local file = io.open(path, "rb")
        
            if not file then
                return nil
            end
        
            local text = file:read("*a")
            file:close()
        
            local ok, value = pcall(wezterm.json_parse, text)
            return ok and value or nil
        end
        
        -- ACTION HELPERS
        -- =====================================================================
        local function add(entries, brief, action, doc, icon)
            table.insert(entries, {
                brief = brief,
                doc = doc,
                icon = icon,
                action = action,
            })
        end
        
        local function shell_action(cwd, command)
            local script = "cd "
                .. wezterm.shell_quote_arg(cwd)
                .. " && "
                .. command
        
            local invocation = wezterm.shell_join_args({
                "sh",
                "-lc",
                script,
            })
        
            return act.SendString(invocation .. "\n")
        end
        
        local function args_action(cwd, args)
            return shell_action(cwd, wezterm.shell_join_args(args))
        end
        
        local function new_tab_action(path, args)
            local command = {
                cwd = path,
                domain = "CurrentPaneDomain",
            }
        
            if args then
                command.args = args
            end
        
            return act.SpawnCommandInNewTab(command)
        end
        
        local function copy_action(text)
            return wezterm.action_callback(function(window)
                window:copy_to_clipboard(text, "Clipboard")
            end)
        end
        
        local function open_with_action(path)
            return wezterm.action_callback(function()
                wezterm.open_with(path)
            end)
        end
        
        local function open_file_action(path)
            return new_tab_action(dirname(path), {
                "micro",
                path,
            })
        end
        
        local function add_location(entries, label, path)
            if not path or not directory_exists(path) then
                return
            end
        
            add(
                entries,
                "Location: " .. label .. " — " .. display_path(path),
                new_tab_action(path),
                "Open this configured location in a new tab"
            )
        end
        
        -- CONTEXT BUILDERS
        -- =====================================================================
        local function add_current_directory_entries(entries, cwd, is_local)
            add(
                entries,
                "Current: New tab here — " .. display_path(cwd),
                new_tab_action(cwd),
                "Open a new tab in the active pane's current directory"
            )
        
            add(
                entries,
                "Current: Copy path — " .. display_path(cwd),
                copy_action(cwd),
                "Copy the active pane's current directory"
            )
        
            local parent = dirname(cwd)
        
            if parent ~= cwd then
                add(
                    entries,
                    "Current: Parent directory — " .. display_path(parent),
                    new_tab_action(parent),
                    "Open the parent directory in a new tab"
                )
            end
        
            if is_local and directory_exists(cwd) then
                add(
                    entries,
                    "Current: Open in file manager — " .. basename(cwd),
                    open_with_action(cwd),
                    "Open the current directory in Finder or the Linux file manager"
                )
        
                add(
                    entries,
                    "Current: Open Yazi — " .. basename(cwd),
                    new_tab_action(cwd, { "yazi", cwd }),
                    "Launch Yazi in the current directory"
                )
            end
        end
        
        local function add_known_locations(entries)
            local projects = first_existing_directory(settings.paths.projects)
            local fish_functions = first_existing_directory(settings.paths.fish_functions)
        
            add_location(entries, "Home", home)
            add_location(entries, "Config", settings.paths.config)
            add_location(entries, "Downloads", settings.paths.downloads)
            add_location(entries, "Projects", projects)
            add_location(entries, "Nix configuration", settings.paths.nix_config)
            add_location(entries, "Fish functions", fish_functions)
        
            if platform.is_macos then
                add_location(entries, "Hammerspoon", settings.paths.hammerspoon)
            end
        end
        
        local function add_wezterm_and_fish(entries)
            add(
                entries,
                "WezTerm: Reload configuration",
                act.ReloadConfiguration,
                "Reload wezterm.lua and all imported modules"
            )
        
            if wezterm.config_file and file_exists(wezterm.config_file) then
                add(
                    entries,
                    "WezTerm: Edit configuration",
                    open_file_action(wezterm.config_file),
                    display_path(wezterm.config_file)
                )
            end
        
            add(
                entries,
                "Fish: Restart current shell",
                act.SendString("exec fish\n"),
                "Replace the current shell with a freshly loaded Fish session"
            )
        
            local fish_config = first_existing_file(settings.paths.fish_configs)
        
            if fish_config then
                add(
                    entries,
                    "Fish: Edit main configuration",
                    open_file_action(fish_config),
                    display_path(fish_config)
                )
            end
        end
        
        local function add_git_entries(entries, cwd)
            local root = git_root(cwd)
        
            if not root then
                return
            end
        
            local label = basename(root)
        
            add(
                entries,
                "Git: Status — " .. label,
                args_action(root, { "git", "status" }),
                display_path(root)
            )
        
            add(
                entries,
                "Git: Diff with Delta — " .. label,
                args_action(root, { "git", "diff" }),
                display_path(root)
            )
        
            add(
                entries,
                "Git: Recent graph — " .. label,
                args_action(root, {
                    "git",
                    "log",
                    "--graph",
                    "--decorate",
                    "--oneline",
                    "--all",
                    "-n",
                    "40",
                }),
                display_path(root)
            )
        
            add(
                entries,
                "Git: Open LazyGit — " .. label,
                new_tab_action(root, { "lazygit" }),
                display_path(root)
            )
        
            add(
                entries,
                "Git: New tab at repository root — " .. label,
                new_tab_action(root),
                display_path(root)
            )
        
            add(
                entries,
                "Git: Copy repository root — " .. label,
                copy_action(root),
                display_path(root)
            )
        end
        
        local function add_nix_entries(entries, cwd)
            local root = find_up(cwd, { "flake.nix" })
        
            if not root then
                return
            end
        
            local label = basename(root)
        
            add(
                entries,
                "Nix: Flake check — " .. label,
                args_action(root, {
                    "nix",
                    "flake",
                    "check",
                    root,
                }),
                display_path(root)
            )
        
            add(
                entries,
                "Nix: Update flake inputs — " .. label,
                args_action(root, {
                    "nix",
                    "flake",
                    "update",
                    "--flake",
                    root,
                }),
                display_path(root)
            )
        
            add(
                entries,
                "Nix: Edit flake.nix — " .. label,
                open_file_action(root .. "/flake.nix"),
                display_path(root .. "/flake.nix")
            )
        
            if platform.is_macos
                and path_is_inside(root, settings.paths.nix_config)
            then
                local flake = root .. "#" .. settings.darwin_host
        
                add(
                    entries,
                    "Nix Darwin: Build — " .. settings.darwin_host,
                    args_action(root, {
                        "sudo",
                        "-H",
                        "darwin-rebuild",
                        "build",
                        "--flake",
                        flake,
                    }),
                    flake
                )
        
                add(
                    entries,
                    "Nix Darwin: Switch — " .. settings.darwin_host,
                    args_action(root, {
                        "sudo",
                        "-H",
                        "darwin-rebuild",
                        "switch",
                        "--flake",
                        flake,
                    }),
                    flake
                )
            end
        end
        
        local function node_package_manager(root)
            if file_exists(root .. "/pnpm-lock.yaml") then
                return "pnpm"
            end
        
            if file_exists(root .. "/yarn.lock") then
                return "yarn"
            end
        
            if file_exists(root .. "/bun.lock")
                or file_exists(root .. "/bun.lockb")
            then
                return "bun"
            end
        
            return "npm"
        end
        
        local function package_script_command(manager, script)
            if manager == "yarn" then
                return { "yarn", script }
            end
        
            return { manager, "run", script }
        end
        
        local function add_node_entries(entries, cwd)
            local root = find_up(cwd, { "package.json" })
        
            if not root then
                return
            end
        
            local package = read_json(root .. "/package.json") or {}
            local scripts = package.scripts or {}
            local manager = node_package_manager(root)
            local label = basename(root)
        
            add(
                entries,
                "Node: Install with " .. manager .. " — " .. label,
                args_action(root, { manager, "install" }),
                display_path(root)
            )
        
            for _, script in ipairs({ "dev", "build", "test", "lint" }) do
                if scripts[script] then
                    add(
                        entries,
                        "Node: " .. manager .. " " .. script .. " — " .. label,
                        args_action(
                            root,
                            package_script_command(manager, script)
                        ),
                        tostring(scripts[script])
                    )
                end
            end
        
            add(
                entries,
                "Node: Edit package.json — " .. label,
                open_file_action(root .. "/package.json"),
                display_path(root .. "/package.json")
            )
        end
        
        local function add_rust_entries(entries, cwd)
            local root = find_up(cwd, { "Cargo.toml" })
        
            if not root then
                return
            end
        
            local manifest = root .. "/Cargo.toml"
            local label = basename(root)
        
            for _, command in ipairs({ "check", "test", "run" }) do
                add(
                    entries,
                    "Rust: cargo " .. command .. " — " .. label,
                    args_action(root, {
                        "cargo",
                        command,
                        "--manifest-path",
                        manifest,
                    }),
                    display_path(root)
                )
            end
        
            add(
                entries,
                "Rust: Edit Cargo.toml — " .. label,
                open_file_action(manifest),
                display_path(manifest)
            )
        end
        
        local function add_python_entries(entries, cwd)
            local root, marker = find_up(cwd, {
                "pyproject.toml",
                "requirements.txt",
                "setup.py",
            })
        
            if not root then
                return
            end
        
            local label = basename(root)
        
            add(
                entries,
                "Python: Run tests — " .. label,
                args_action(root, {
                    "python",
                    "-m",
                    "pytest",
                    root,
                }),
                display_path(root)
            )
        
            add(
                entries,
                "Python: Create .venv — " .. label,
                args_action(root, {
                    "python",
                    "-m",
                    "venv",
                    root .. "/.venv",
                }),
                display_path(root .. "/.venv")
            )
        
            add(
                entries,
                "Python: Edit " .. marker .. " — " .. label,
                open_file_action(root .. "/" .. marker),
                display_path(root .. "/" .. marker)
            )
        end
        
        local function add_go_entries(entries, cwd)
            local root = find_up(cwd, { "go.mod" })
        
            if not root then
                return
            end
        
            local label = basename(root)
        
            add(
                entries,
                "Go: Test all packages — " .. label,
                shell_action(root, "go test ./..."),
                display_path(root)
            )
        
            add(
                entries,
                "Go: Run project — " .. label,
                shell_action(root, "go run ."),
                display_path(root)
            )
        
            add(
                entries,
                "Go: Edit go.mod — " .. label,
                open_file_action(root .. "/go.mod"),
                display_path(root .. "/go.mod")
            )
        end
        
        local function add_docker_entries(entries, cwd)
            local root, compose_file = find_up(cwd, {
                "compose.yml",
                "compose.yaml",
                "docker-compose.yml",
                "docker-compose.yaml",
            })
        
            if not root then
                return
            end
        
            local file = root .. "/" .. compose_file
            local label = basename(root)
            local prefix = wezterm.shell_join_args({
                "docker",
                "compose",
                "-f",
                file,
            })
        
            add(
                entries,
                "Docker: Compose status — " .. label,
                shell_action(root, prefix .. " ps"),
                display_path(file)
            )
        
            add(
                entries,
                "Docker: Compose up — " .. label,
                shell_action(root, prefix .. " up -d"),
                display_path(file)
            )
        
            add(
                entries,
                "Docker: Compose logs — " .. label,
                shell_action(root, prefix .. " logs --tail=100"),
                display_path(file)
            )
        
            add(
                entries,
                "Docker: Compose down — " .. label,
                shell_action(root, prefix .. " down"),
                display_path(file)
            )
        end
        
        local function add_task_runner_entries(entries, cwd)
            local just_root, just_file = find_up(cwd, {
                "justfile",
                "Justfile",
            })
        
            if just_root then
                add(
                    entries,
                    "Just: List recipes — " .. basename(just_root),
                    args_action(just_root, {
                        "just",
                        "--justfile",
                        just_root .. "/" .. just_file,
                        "--working-directory",
                        just_root,
                        "--list",
                    }),
                    display_path(just_root)
                )
            end
        
            local task_root = find_up(cwd, {
                "Taskfile.yml",
                "Taskfile.yaml",
            })
        
            if task_root then
                add(
                    entries,
                    "Task: List tasks — " .. basename(task_root),
                    args_action(task_root, {
                        "task",
                        "--dir",
                        task_root,
                        "--list",
                    }),
                    display_path(task_root)
                )
            end
        end
        
        -- PALETTE EVENT
        -- =====================================================================
        wezterm.on("augment-command-palette", function(_, pane)
            local entries = {}
            local cwd = cwd_to_path(pane:get_current_working_dir())
            local domain = pane:get_domain_name() or ""
            local is_local = domain == "local"
                or domain:match("^local") ~= nil
        
            add_current_directory_entries(entries, cwd, is_local)
            add_wezterm_and_fish(entries)
        
            if is_local then
                add_known_locations(entries)
                add_git_entries(entries, cwd)
                add_nix_entries(entries, cwd)
                add_node_entries(entries, cwd)
                add_rust_entries(entries, cwd)
                add_python_entries(entries, cwd)
                add_go_entries(entries, cwd)
                add_docker_entries(entries, cwd)
                add_task_runner_entries(entries, cwd)
            end
        
            return entries
        end)
        
        -- CONFIG APPLICATION
        -- =====================================================================
        local function normalize_mods(mods)
            local parts = {}
        
            for part in tostring(mods or ""):gmatch("[^|]+") do
                table.insert(parts, part)
            end
        
            table.sort(parts)
            return table.concat(parts, "|")
        end
        
        function M.apply(config)
            config.command_palette_rows = settings.palette_rows
            config.keys = config.keys or {}
        
            local wanted_mods = normalize_mods(
                platform.super .. "|SHIFT"
            )
        
            -- Remove older copies of this shortcut before adding the final binding.
            for index = #config.keys, 1, -1 do
                local binding = config.keys[index]
                local same_key = binding.key == "P"
                    or binding.key == "phys:P"
                    or binding.key == "mapped:P"
        
                if same_key
                    and normalize_mods(binding.mods) == wanted_mods
                then
                    table.remove(config.keys, index)
                end
            end
        
            table.insert(config.keys, {
                -- Open command palette
                -- Opens WezTerm's built in command palette, sized to the row
                -- count set above. Duplicate copies of this shortcut are
                -- removed first, so the binding stays unique.
                --
                -- macOS: Command + Shift + P
                -- Linux: Super + Shift + P
                key = "phys:P",
                mods = platform.super .. "|SHIFT",
                action = act.ActivateCommandPalette,
            })
        end
        
        M.apply(config)
      end
    '';
  };
}

