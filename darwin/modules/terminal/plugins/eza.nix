# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/eza.nix
#
# ZSH: EZA
# =========================
# A modern replacement for ls

{ ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;

    colors = "auto";
    icons = "auto";

    theme = {
      filekinds = {
        normal = {
          foreground = "#e0def4";
        };

        directory = {
          foreground = "#9ccfd8";
          is-bold = true;
        };

        symlink = {
          foreground = "#c4a7e7";
        };

        executable = {
          foreground = "#3e8fb0";
          is-bold = true;
        };

        pipe = {
          foreground = "#f6c177";
        };

        socket = {
          foreground = "#ea9a97";
        };

        block-device = {
          foreground = "#eb6f92";
        };

        char-device = {
          foreground = "#eb6f92";
        };

        special = {
          foreground = "#908caa";
        };
      };

      perms = {
        user-read = {
          foreground = "#9ccfd8";
        };

        user-write = {
          foreground = "#f6c177";
        };

        user-execute = {
          foreground = "#3e8fb0";
        };

        group-read = {
          foreground = "#c4a7e7";
        };

        group-write = {
          foreground = "#ea9a97";
        };

        group-execute = {
          foreground = "#eb6f92";
        };

        other-read = {
          foreground = "#908caa";
        };

        other-write = {
          foreground = "#6e6a86";
        };

        other-execute = {
          foreground = "#6e6a86";
        };

        special-user-file = {
          foreground = "#eb6f92";
        };

        special-other = {
          foreground = "#eb6f92";
        };

        attribute = {
          foreground = "#6e6a86";
        };
      };

      size = {
        number = {
          foreground = "#f6c177";
        };

        unit = {
          foreground = "#908caa";
        };
      };

      users = {
        user-you = {
          foreground = "#c4a7e7";
          is-bold = true;
        };

        user-root = {
          foreground = "#eb6f92";
          is-bold = true;
        };

        user-other = {
          foreground = "#e0def4";
        };

        group-your = {
          foreground = "#9ccfd8";
        };

        group-other = {
          foreground = "#908caa";
        };

        group-root = {
          foreground = "#eb6f92";
        };
      };

      dates = {
        hour-old = {
          foreground = "#3e8fb0";
        };

        day-old = {
          foreground = "#9ccfd8";
        };

        older = {
          foreground = "#6e6a86";
        };
      };

      git = {
        new = {
          foreground = "#9ccfd8";
        };

        modified = {
          foreground = "#ea9a97";
        };

        deleted = {
          foreground = "#eb6f92";
        };

        renamed = {
          foreground = "#3e8fb0";
        };

        typechange = {
          foreground = "#f6c177";
        };

        ignored = {
          foreground = "#6e6a86";
        };

        conflicted = {
          foreground = "#eb6f92";
          is-bold = true;
        };
      };
    };
  };
}