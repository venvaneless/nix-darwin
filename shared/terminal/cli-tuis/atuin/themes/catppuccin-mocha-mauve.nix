# shared/terminal/cli-tuis/atuin/themes/catppuccin-mocha-mauve.nix
#
# =====================================================================
# ATUIN: CATPPUCCIN MOCHA MAUVE THEME
#
# - Preserves the archived custom Atuin theme in Nix
# - Toggle with ven.features.terminal.cliTuis.atuin.themes.catppuccinMochaMauve.enable
# - Disabled by default; enable it after turning the active theme off
# =====================================================================

{ config, lib, ... }:

let
  atuinCfg = config.ven.features.terminal.cliTuis.atuin;
  cfg = atuinCfg.themes.catppuccinMochaMauve;
in
{
  options.ven.features.terminal.cliTuis.atuin.themes.catppuccinMochaMauve.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use the archived Catppuccin Mocha Mauve theme for Atuin.";
  };

  # Only applies when Atuin itself is enabled.
  config = lib.mkIf (atuinCfg.enable && cfg.enable) {
    # The archived theme is retained unchanged in a Nix-managed theme file.
    xdg.configFile."atuin/themes/catppuccin-mocha-mauve.toml".text = ''
      [theme]
      name = "catppuccin-mocha-mauve"

      [colors]
      AlertInfo = "#a6e3a1"
      AlertWarn = "#fab387"
      AlertError = "#f38ba8"
      Annotation = "#cba6f7"
      Base = "#cdd6f4"
      Guidance = "#9399b2"
      Important = "#f38ba8"
      Title = "#cba6f7"
    '';

    programs.atuin.settings.theme.name = "catppuccin-mocha-mauve";
  };
}
