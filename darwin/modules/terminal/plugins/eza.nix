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
          foreground = "#ffffff";
        };

        directory = {
          foreground = "#ffffff";
          is-bold = true;
        };

        symlink = {
          foreground = "#ffffff";
        };

        executable = {
          foreground = "#ffffff";
          is-bold = true;
        };

        pipe = {
          foreground = "#ffffff";
        };

        socket = {
          foreground = "#ffffff";
        };

        block-device = {
          foreground = "#ffffff";
        };

        char-device = {
          foreground = "#ffffff";
        };

        special = {
          foreground = "#ffffff";
        };
      };

      perms = {
        user-read = {
          foreground = "#ffffff";
        };

        user-write = {
          foreground = "#ffffff";
        };

        user-execute = {
          foreground = "#ffffff";
        };

        group-read = {
          foreground = "#ffffff";
        };

        group-write = {
          foreground = "#ffffff";
        };

        group-execute = {
          foreground = "#ffffff";
        };

        other-read = {
          foreground = "#ffffff";
        };

        other-write = {
          foreground = "#ffffff";
        };

        other-execute = {
          foreground = "#ffffff";
        };

        special-user-file = {
          foreground = "#ffffff";
        };

        special-other = {
          foreground = "#ffffff";
        };

        attribute = {
          foreground = "#ffffff";
        };
      };

      size = {
        number = {
          foreground = "#ffffff";
        };

        unit = {
          foreground = "#ffffff";
        };
      };

      users = {
        user-you = {
          foreground = "#ffffff";
          is-bold = true;
        };

        user-root = {
          foreground = "#ffffff";
          is-bold = true;
        };

        user-other = {
          foreground = "#ffffff";
        };

        group-your = {
          foreground = "#ffffff";
        };

        group-other = {
          foreground = "#ffffff";
        };

        group-root = {
          foreground = "#ffffff";
        };
      };

      dates = {
        hour-old = {
          foreground = "#ffffff";
        };

        day-old = {
          foreground = "#ffffff";
        };

        older = {
          foreground = "#ffffff";
        };
      };

      git = {
        new = {
          foreground = "#ffffff";
        };

        modified = {
          foreground = "#ffffff";
        };

        deleted = {
          foreground = "#ffffff";
        };

        renamed = {
          foreground = "#ffffff";
        };

        typechange = {
          foreground = "#ffffff";
        };

        ignored = {
          foreground = "#ffffff";
        };

        conflicted = {
          foreground = "#ffffff";
          is-bold = true;
        };
      };
    };
  };
}