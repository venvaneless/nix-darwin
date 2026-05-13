# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/fastfetch.nix
# 
# =====================================================================
# FASTFETCH
# 
# Feature-rich and performance oriented,
# neofetch like system information tool
# =====================================================================

{ pkgs, ... }:

{
  home.packages = [ pkgs.fastfetch ];

  xdg.configFile."fastfetch.jsonc".source =
    builtins.path {
      path = "/Users/ven/.config/fastfetch.jsonc";
      name = "fastfetch.jsonc";
    };

    xdg.configFile."ascii.txt".source =
      builtins.path {
        path = "/Users/ven/.config/ascii.txt";
        name = "ascii.txt";
      };

  programs.fish.interactiveShellInit = ''
    function __find_terminal_pid
      set -l pid $fish_pid

      while test "$pid" -gt 1
        set -l comm (ps -p $pid -o comm= 2>/dev/null | string trim)

        switch $comm
          case wezterm-gui kitty alacritty ghostty Terminal iTerm2
            echo $pid
            return 0
        end

        set pid (ps -p $pid -o ppid= 2>/dev/null | string trim)

        if test -z "$pid"
          return 1
        end
      end

      return 1
    end

    for marker in /tmp/fastfetch-$UID-*
      if test -e "$marker"
        set -l marker_pid (basename "$marker" | string replace "fastfetch-$UID-" "")
        kill -0 $marker_pid >/dev/null 2>&1
        or rm -f "$marker"
      end
    end

    set -l terminal_pid (__find_terminal_pid)

    if test -n "$terminal_pid"
      set -l marker "/tmp/fastfetch-$UID-$terminal_pid"

      if not test -e "$marker"
        touch "$marker"
        fastfetch --config "$HOME/.config/fastfetch.jsonc"
      end
    end
  '';
}