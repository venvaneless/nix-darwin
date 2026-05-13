# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/fastfetch.nix
#
# =====================================================================
# FASTFETCH
#
# Feature-rich and performance oriented,
# neofetch like system information tool
# =====================================================================

{ pkgs, config, ... }:

{
  home.packages = [
    pkgs.fastfetch
  ];

  programs.fish.shellInit = ''
    # FISH: FASTFETCH
    # =========================

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
        fastfetch --config "${config.home.homeDirectory}/.config/fastfetch/fastfetch-current.jsonc"
      end
    end
  '';
}