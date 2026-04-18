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
    hash = lib.fakeHash;
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

      manager = {
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

    theme = {
      filetype = {
        rules = [
          { fg = "#89b4fa"; mime = "image/*"; }
          { fg = "#fab387"; mime = "video/*"; }
          { fg = "#f9e2af"; mime = "audio/*"; }
          { fg = "#cba6f7"; mime = "application/*zip"; }
          { fg = "#cba6f7"; mime = "application/x-tar"; }
          { fg = "#a6e3a1"; mime = "text/*"; }
        ];
      };

      manager = {
        hovered = {
          reversed = true;
        };

        preview_hovered = {
          underline = true;
        };

        find_keyword = {
          fg = "#f5c2e7";
          bold = true;
        };

        find_position = {
          fg = "#f9e2af";
          bold = true;
        };

        marker_copied = {
          fg = "#1e1e2e";
          bg = "#a6e3a1";
        };

        marker_cut = {
          fg = "#1e1e2e";
          bg = "#f38ba8";
        };

        marker_selected = {
          fg = "#1e1e2e";
          bg = "#89b4fa";
        };

        tab_active = {
          fg = "#1e1e2e";
          bg = "#89b4fa";
          bold = true;
        };

        tab_inactive = {
          fg = "#cdd6f4";
          bg = "#313244";
        };

        border_style = {
          fg = "#6c7086";
        };
      };

      which = {
        cand = {
          fg = "#89b4fa";
        };

        desc = {
          fg = "#f5c2e7";
        };

        separator_style = {
          fg = "#6c7086";
        };
      };

      notify = {
        title_info = {
          fg = "#89b4fa";
        };

        title_warn = {
          fg = "#f9e2af";
        };

        title_error = {
          fg = "#f38ba8";
        };
      };
    };

    # plugins = {
    #   "full-border" = pkgs.yaziPlugins."full-border";
    #   git = pkgs.yaziPlugins.git;
    #   ouch = pkgs.yaziPlugins.ouch;
    #   chmod = pkgs.yaziPlugins.chmod;
    #   mactag = pkgs.yaziPlugins.mactag;
    # };
  };
}