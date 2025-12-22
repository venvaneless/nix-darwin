# darwin/modules/terminal/nvim.nix
{ pkgs, ... }:

{
  # Install binaries only
  home.packages = [
    pkgs.neovim
    pkgs.neovide
  ];

  # Point Neovide to YOUR config dir
  home.sessionVariables = {
    NEOVIDE_CONFIG = "/Users/ven/ven-dots/user-data/apps/neovide";
  };
}
