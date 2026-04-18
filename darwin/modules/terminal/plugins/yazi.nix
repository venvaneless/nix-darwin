# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/yazi.nix
#
# =============================================================
# YAZI
# Blazing fast terminal file manager written in Rust,
# based on async I/O
# =============================================================

{ pkgs, lib, ... }:

let
  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    hash = "sha256-Gm6ThktOLUR+KDs6f3s1WCgrw2TOKQ4tolVvVdCxnCM=";
  };
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    flavors = {
      catppuccin-mocha = "${yaziFlavors}/catppuccin-mocha.yazi";
    };

    settings = {
      flavor = {
        dark = "catppuccin-mocha";
      };

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
}