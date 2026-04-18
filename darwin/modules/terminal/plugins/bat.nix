# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/bat.nix
#
# =============================================================
# BAT
# Cat clone with syntax highlighting and Git integration
# Includes bat-extras helper tools
# =============================================================

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
      pager = "less -R -X";
      style = "numbers,changes,header";
      italic-text = "always";
    };

    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batgrep
      batpipe
      batwatch
    ];
  };

  programs.zsh.shellAliases = {
  
  # --- cat -> bat
  	# Use bat instead of cat for syntax highlighting and nicer output
    cat = "bat";
    
    # use batdiff instead of standard diff
    diff = "batdiff";
    
    # use batman for man pages
    man = "batman";
  };
}