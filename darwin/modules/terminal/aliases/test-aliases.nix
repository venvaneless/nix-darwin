# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/test-aliases.nix

{ lib, ... }:

{
  programs.zsh.shellAliases = {
  	ess = "exec zsh";
  };
}
