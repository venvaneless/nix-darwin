# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/bat.nix
#
# ZSH: BAT
# =========================
# Cat clone with syntax highlighting and Git integration

{ ... }:

{
  programs.bat = {
    enable = true;
    enableGitIntegration = true;
  };
  
  programs.zsh.sessionVariables = {
    BAT_THEME = "Rose Pine";
    BAT_PAGER = "less -R"; # ensures colors render correctly
  };
}