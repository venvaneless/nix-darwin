# shared/terminal/wezterm/overlays/wez-overlays.nix
#
# Embedded Lua configuration for WezTerm.

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.wezterm;
in
{
  imports = [
    ./quick_commands/wez-actions.nix
    ./quick_commands/wez-folders.nix
    ./quick_commands/wez-menu.nix
  ];

  config = lib.mkIf cfg.enable {
    programs.wezterm.extraConfig = lib.mkAfter /* lua */ ''
      do
        local wezterm = require("wezterm")
        
        local quick_commands_menu =
          require("ven.wezterm.quick_commands.menu")
        
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
      end
    '';
  };
}
