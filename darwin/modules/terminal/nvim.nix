# darwin/modules/terminal/nvim.nix
{ pkgs, ... }:

{
  home.packages = [ pkgs.neovim ];

  programs.neovide = {
    enable = true;
    settings = {
      frame = "full";
      idle = true;
      maximized = true;
    };
  };

  home.sessionVariables = {
    NEOVIDE_CONFIG = "/Users/ven/ven-dots/user-data/neovide";
  };
}
