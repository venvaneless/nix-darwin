# shared/terminal/cli-tuis/micro/themes/micro-themes-schemas.nix
#
# =====================================================================
# MICRO: THEME SCHEMAS
#
# Declarative list of Micro colour scheme files managed by Nix.
# Generates Micro's colorschemes.json index.
# =====================================================================

{ config, lib, ... }:

let
  microCfg = config.ven.features.terminal.cliTuis.micro;

  themes = [
    "atom-dark.micro"
    "bubblegum.micro"
    "catppuccin-mocha.micro"
    "cmc-16.micro"
    "cmc-tc.micro"
    "darcula.micro"
    "default.micro"
    "dracula-tc.micro"
    "dukedark-tc.micro"
    "dukelight-tc.micro"
    "dukeubuntu-tc.micro"
    "geany.micro"
    "gotham.micro"
    "gruvbox.micro"
    "gruvbox-tc.micro"
    "gruvbox-light.micro"
    "material-tc.micro"
    "monokai-dark.micro"
    "monokai.micro"
    "one-dark.micro"
    "railscast.micro"
    "simple.micro"
    "solarized-tc.micro"
    "solarized.micro"
    "sunny-day.micro"
    "test-scheme.micro"
    "twilight.micro"
    "zenburn.micro"
  ];

  themesJson = builtins.toJSON themes;
in
{
  config = lib.mkIf microCfg.enable {
    xdg.configFile."micro/colorschemes.json".text = themesJson;
  };
}
