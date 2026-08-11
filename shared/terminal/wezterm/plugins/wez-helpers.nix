# shared/terminal/wezterm/plugins/wez-helpers.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/helpers.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "helpers.lua" /* lua */ ''
    -- shared/terminal/wezterm/plugins/helpers.lua

    local M = {}

    function M.append_keys(config, keys)
        config.keys = config.keys or {}

        for _, key in ipairs(keys) do
            table.insert(config.keys, key)
        end
    end

    return M
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/helpers.lua".source = luaConfig;
  };
}
