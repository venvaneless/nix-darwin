# shared/terminal/themes/fish-gruvbox-theme.nix

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf
      (config.terminal.fish.theme == "gruvbox")
      {
        programs.fish.plugins = [
          {
            # Install the theme from the fishPlugins package set
            name = "gruvbox";
            src = pkgs.fishPlugins.gruvbox.src;
          }
        ];

        programs.fish.interactiveShellInit = ''
          theme_gruvbox dark medium
        '';
      };
}
