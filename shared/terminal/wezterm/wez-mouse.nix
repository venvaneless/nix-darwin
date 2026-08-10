# shared/terminal/wezterm/wez-mouse.nix

{ lib, ... }:

{
  mouse_bindings = [
    {
      event = {
        Up = {
          streak = 1;
          button = "Left";
        };
      };

      mods = "NONE";

      action = lib.generators.mkLuaInline ''
        wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor(
            "ClipboardAndPrimarySelection"
        )
      '';
    }
  ];
}