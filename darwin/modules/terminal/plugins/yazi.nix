# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/yazi.nix
#
# =============================================================
# YAZI
# Blazing fast terminal file manager written in Rust,
# based on async I/O
# =============================================================

{ pkgs, lib, ... }:

let
  catppuccinFlavors = pkgs.fetchFromGitHub {
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
        edit = [{
          run = "micro \"$@\"";
          block = true;
          desc = "Edit in micro";
        }];

        open = [{
          run = "open \"$@\"";
          desc = "Open";
        }];

        reveal = [{
          run = "open -R \"$1\"";
          orphan = true;
          desc = "Reveal in Finder";
        }];
      };

      open.rules = [
        { mime = "text/*"; use = [ "edit" ]; }
        { name = "*.md";   use = [ "edit" ]; }
      ];
    };
  };

  xdg.configFile."yazi/theme.toml".text = ''
    [flavor]
    dark = "catppuccin-mocha"
  
    [mgr]
    cwd = { fg = "#b4befe" }
    hovered = { fg = "#b4befe", bold = true }
    preview_hovered = { underline = true }
  
    find_keyword  = { fg = "#f9e2af", italic = true }
    find_position = { fg = "#b4befe", bg = "reset", italic = true }
  
    marker_selected = { fg = "#b4befe", bg = "#b4befe" }
    count_selected  = { fg = "#1e1e2e", bg = "#b4befe" }
  
    [tabs]
    active = { fg = "#1e1e2e", bg = "#cdd6f4", bold = true }
  
    [mode]
    normal_main = { fg = "#1e1e2e", bg = "#b4befe", bold = true }
    normal_alt  = { fg = "#b4befe", bg = "#313244" }
  
    [input]
    border = { fg = "#b4befe" }
  
    [pick]
    border = { fg = "#b4befe" }
  
    [confirm]
    border = { fg = "#b4befe" }
    title  = { fg = "#b4befe" }
  
    [cmp]
    border = { fg = "#b4befe" }
  
    [tasks]
    border = { fg = "#b4befe" }
  '';

  xdg.configFile."yazi/flavors/catppuccin-mocha.yazi/flavor.toml".source =
    "${catppuccinFlavors}/catppuccin-mocha.yazi/flavor.toml";

  xdg.configFile."yazi/flavors/catppuccin-mocha.yazi/tmtheme.xml".source =
    "${catppuccinFlavors}/catppuccin-mocha.yazi/tmtheme.xml";
}