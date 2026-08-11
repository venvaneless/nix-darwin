# shared/terminal/wezterm/plugins/wez-helpers.nix
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
        package.preload["ven.wezterm.plugins.helpers"] = function()
          -- shared/terminal/wezterm/plugins/helpers.lua
          
          local M = {}
          
          function M.append_keys(config, keys)
              config.keys = config.keys or {}
          
              for _, key in ipairs(keys) do
                  table.insert(config.keys, key)
              end
          end
          
          return M
        end
      end
    '';
  };
}

