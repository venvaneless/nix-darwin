# options/cli/atuin/themes/gruvbox-dark.nix
#
# =====================================================================
# ATUIN: GRUVBOX DARK THEME
#
# - Uses the Gruvbox Dark palette shared by the active WezTerm theme
# - Toggle with home.shared.cli.atuin.themes.gruvboxDark.enable
# - Enabled by default; this is the active Atuin theme
# =====================================================================

{ config, lib, ... }:

let
  atuinCfg = config.home.shared.cli.atuin;
  cfg = atuinCfg.themes.gruvboxDark;
in
{
  options.home.shared.cli.atuin.themes.gruvboxDark.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use the Gruvbox Dark theme for Atuin.";
  };

  # Only applies when Atuin itself is enabled.
  config = lib.mkIf (atuinCfg.enabledForCurrentPlatform && cfg.enable) {
    # Match WezTerm's Gruvbox Dark foreground and accent colours.
    xdg.configFile."atuin/themes/gruvbox-dark.toml".text = ''
      [theme]
      name = "gruvbox-dark"

      [colors]
      AlertInfo = "#b8bb26"
      AlertWarn = "#fabd2f"
      AlertError = "#fb4934"
      Annotation = "#d3869b"
      Base = "#ebdbb2"
      Guidance = "#a89984"
      Important = "#fe8019"
      Title = "#83a598"
    '';

    programs.atuin.settings.theme.name = "gruvbox-dark";
  };
}
