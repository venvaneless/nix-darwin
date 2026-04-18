# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/bat.nix

{ pkgs, lib, ... }:

{
  programs.bat = {
    enable = true;

    themes = {
      rose-pine-moon = {
        src = pkgs.fetchFromGitHub {
          owner = "drluckyspin";
          repo = "rose-pine-bat";
          rev = "main";
          hash = lib.fakeHash;
        };
        file = "themes/Rose-Pine-Moon.tmTheme";
      };
    };

    settings = {
      theme = "Rose-Pine-Moon";
      paging = "auto";
      pager = "less -R";
    };
  };

  programs.zsh.shellAliases = {
    cat = "bat";
  };
}