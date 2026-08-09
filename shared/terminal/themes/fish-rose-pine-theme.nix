# shared/terminal/themes/fish-rose-pine-theme.nix

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf
      (config.ven.features.terminal.fish.themes.enable && config.terminal.fish.theme == "rose-pine")
      {
        programs.fish.plugins = [
          {
            # Download the theme from Github
            name = "rose-pine";
            src = pkgs.fetchFromGitHub {
              owner = "rose-pine";
              repo = "fish";
              rev = "main";
              hash = "sha256-3heI6nhItw5WfKGQT1FRQKfv+lONyn+DzwYjYqJjzLE=";
            };
          }
        ];
      };
}
