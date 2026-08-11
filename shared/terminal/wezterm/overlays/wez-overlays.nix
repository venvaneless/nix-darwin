# shared/terminal/wezterm/overlays/wez-overlays.nix
#
# Embedded Lua source generated into .config/wezterm/overlays/overlays.lua.

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.wezterm;

  luaConfig = pkgs.writeText "overlays.lua" /* lua */ ''
    local wezterm = require("wezterm")

    local quick_commands_menu =
      dofile(wezterm.config_dir .. "/overlays/quick_commands/menu.lua")

    wezterm.on("augment-command-palette", function(window, pane)
      return {
        {
          brief = "Quick commands",
          icon = "md_flash",
          action = wezterm.action_callback(function(window, pane)
            quick_commands_menu.show(window, pane)
          end),
        },
      }
    end)
  '';
in
{
  imports = [
    ./quick_commands/wez-actions.nix
    ./quick_commands/wez-folders.nix
    ./quick_commands/wez-menu.nix
  ];

  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/overlays/overlays.lua".source = luaConfig;
  };
}
