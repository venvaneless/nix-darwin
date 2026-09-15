# options/package-options/wezterm/plugins/wez-helpers.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/helpers.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.home.shared.terminal.wezterm;

  luaConfig = pkgs.writeText "helpers.lua" /* lua */ ''
    -- options/package-options/wezterm/plugins/helpers.lua

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
  options.home.shared.terminal.wezterm.plugins.modules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "WezTerm plugin modules loaded in order.";
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/helpers.lua".source = luaConfig;
  };
}
