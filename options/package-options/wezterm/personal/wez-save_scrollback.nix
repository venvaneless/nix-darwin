# options/package-options/wezterm/personal/wez-save_scrollback.nix
#
# Embedded Lua source generated into .config/wezterm/personal/save_scrollback.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.shared.terminal.wezterm;

  luaConfig = pkgs.writeText "save_scrollback.lua" /* lua */ ''
    -- options/package-options/wezterm/personal/save_scrollback.lua
    --
    -- Writes the visible terminal plus its retained scrollback to a file
    -- in Downloads and copies the same text to the clipboard.

    local wezterm = require("wezterm")

    local platform = dofile(
        wezterm.config_dir .. "/personal/platform.lua"
    )

    local M = {}

    local settings = {
      output_dir = os.getenv("HOME") .. "/${cfg.personal.saveScrollback.outputDirectory}",
      file_name = ${builtins.toJSON cfg.personal.saveScrollback.fileName},
      timestamp_separator = ${builtins.toJSON cfg.personal.saveScrollback.timestampSeparator},
      timestamp_format = ${builtins.toJSON cfg.personal.saveScrollback.timestampFormat},
      extension = ${builtins.toJSON cfg.personal.saveScrollback.extension},
      key = ${builtins.toJSON cfg.personal.saveScrollback.key},
      modifiers = ${lib.generators.toLua { } cfg.personal.saveScrollback.modifiers},
    }

    local function modifier_string(modifiers)
        local parts = {}

        for _, modifier in ipairs(modifiers) do
            table.insert(
                parts,
                modifier == "SUPER" and platform.super or modifier
            )
        end

        return table.concat(parts, "|")
    end

    local function save_scrollback(window, pane)
        local dimensions = pane:get_dimensions()

        -- Get the visible terminal plus retained scrollback.
        local text = pane:get_lines_as_text(dimensions.scrollback_rows)

        local filename = settings.file_name
            .. settings.timestamp_separator
            .. os.date(settings.timestamp_format)
            .. "."
            .. settings.extension
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
            mods = modifier_string(settings.modifiers),
            action = wezterm.action_callback(save_scrollback),
        })
    end

    return M
  '';
in
{
  options.shared.terminal.wezterm.personal.saveScrollback = {
    outputDirectory = lib.mkOption {
      type = lib.types.str;
      description = "Scrollback export directory relative to the user's home directory.";
    };

    fileName = lib.mkOption {
      type = lib.types.str;
      description = "Base name used before the timestamp in exported scrollback files.";
    };

    timestampSeparator = lib.mkOption {
      type = lib.types.str;
      description = "Text placed between the scrollback base name and timestamp.";
    };

    timestampFormat = lib.mkOption {
      type = lib.types.str;
      description = "strftime pattern appended to the scrollback base name.";
    };

    extension = lib.mkOption {
      type = lib.types.str;
      description = "File extension for exported scrollback files, without the leading dot.";
    };

    key = lib.mkOption {
      type = lib.types.str;
      description = "WezTerm key used by the personal save-scrollback shortcut.";
    };

    modifiers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Platform-neutral modifiers for the save-scrollback shortcut.";
    };
  };

  # save_scrollback.lua loads platform.lua at runtime.
  imports = [
    ./wez-platform.nix
  ];

  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/personal/save_scrollback.lua".source = luaConfig;
  };
}
