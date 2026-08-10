# shared/terminal/cli-tuis/bat/bat-gruvbox.nix
#
# =====================================================================
# BAT: GRUVBOX DARK THEME
#
# - Selects bat's built-in `gruvbox-dark` syntax theme
# - Matches the theme Delta already uses for Git output
# - Toggle with ven.features.terminal.cliTuis.bat.gruvbox.enable
# - Turning it off falls back to bat's built-in default theme
#
# The theme ships with bat, so no `bat cache --build` step is needed.
# =====================================================================

{ config, lib, ... }:

let
  batCfg = config.ven.features.terminal.cliTuis.bat;
  cfg = batCfg.gruvbox;
in
{
  options.ven.features.terminal.cliTuis.bat.gruvbox.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use the Gruvbox Dark syntax theme for bat.";
  };

  # Only applies when bat itself is enabled.
  config = lib.mkIf (batCfg.enable && cfg.enable) {
    programs.bat.config.theme = "gruvbox-dark";
  };
}
