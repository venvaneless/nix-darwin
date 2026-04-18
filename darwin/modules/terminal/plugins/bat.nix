# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/bat.nix
#
# ZSH: BAT
# =========================
# Cat clone with syntax highlighting and Git integration

{ pkgs, lib, ... }:

{
  programs.bat = {
    enable = true;

    themes = {
      "Rose-Pine-Moon" = {
        src = pkgs.fetchFromGitHub {
          owner = "drluckyspin";
          repo = "rose-pine-bat";
          rev = "main";
          hash = "sha256-p0AR47OtBcQyyGJOjf+EjRQw0ckyUhcdeRqb7sA0zLI=";
        };
        file = "themes/Rose-Pine-Moon.tmTheme";
      };
    };

    config = {
      theme = "Rose-Pine-Moon";
      paging = "auto";
      pager = "less -R";
    };
  };

  programs.zsh.shellAliases = {
    cat = "bat";
  };
}