# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/yazi.nix
#
# =============================================================
# YAZI
# Blazing fast terminal file manager written in Rust,
# based on async I/O
# =============================================================

{ pkgs, lib, ... }:

let
  catppuccinYazi = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "main";
    hash = "sha256-Og33IGS9pTim6LEH33CO102wpGnPomiperFbqfgrJjw=";
  };

  catppuccinBat = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "main";
    hash = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
  };
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        show_symlink = true;
        scrolloff = 8;
      };

      preview = {
        wrap = "no";
        tab_size = 2;
      };

      opener = {
        edit = [
          {
            run = "micro \"$@\"";
            block = true;
            desc = "Edit in micro";
          }
        ];

        open = [
          {
            run = "open \"$@\"";
            desc = "Open";
          }
        ];

        reveal = [
          {
            run = "open -R \"$1\"";
            orphan = true;
            desc = "Reveal in Finder";
          }
        ];
      };

      open = {
        rules = [
          {
            mime = "text/*";
            use = [ "edit" ];
          }
          {
            name = "*.md";
            use = [ "edit" ];
          }
        ];
      };
    };

    plugins = {
      # Adds full borders around panes
      "full-border" = pkgs.yaziPlugins."full-border";

      # Shows Git status in Yazi
      git = pkgs.yaziPlugins.git;

      # Archive integration
      ouch = pkgs.yaziPlugins.ouch;

      # Interactive chmod inside Yazi
      chmod = pkgs.yaziPlugins.chmod;

      # macOS Finder tags integration
      mactag = pkgs.yaziPlugins.mactag;
    };
  };

  xdg.configFile."yazi/theme.toml".text =
    builtins.readFile "${catppuccinYazi}/themes/mocha/catppuccin-mocha-mauve.toml";

  xdg.configFile."yazi/Catppuccin-mocha.tmTheme".text =
    builtins.readFile "${catppuccinBat}/themes/Catppuccin Mocha.tmTheme";
}