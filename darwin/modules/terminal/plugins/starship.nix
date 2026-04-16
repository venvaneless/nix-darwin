# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/starship.nix
#
# ZSH: STARSHIP PROMPT
# ============================================================

{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    sessionVariables = {
      STARSHIP_CONFIG = "${config.home.homeDirectory}/.config/starship.toml";
      STARSHIP_CACHE = "${config.home.homeDirectory}/.config/.cache/";
    };
  };
}
