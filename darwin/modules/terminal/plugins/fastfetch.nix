# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/fastfetch.nix

{ lib, pkgs, ... }:

{
 	{
	  programs.fastfetch = {
	    enable = true;
   };

  programs.zsh.initContent = ''
    if [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1; then
      fastfetch --load-config "$HOME/.config/fastfetch.jsonc"
    fi
  '';
}
