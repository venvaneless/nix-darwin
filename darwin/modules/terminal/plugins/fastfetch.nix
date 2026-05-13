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
    # FASTFETCH
    # =========================
    # Run once per interactive Fish shell session.

    status is-interactive; or return

    set -l fastfetch_config "${config.home.homeDirectory}/.config/fastfetch/fastfetch-macos.jsonc"
    set -l fastfetch_marker "$TMPDIR/fastfetch-shown-$USER-$fish_pid"

    if type -q fastfetch
      if test -f "$fastfetch_config"
        if not test -e "$fastfetch_marker"
          touch "$fastfetch_marker"
          fastfetch --config "$fastfetch_config"
        end
      end
    end
  '';
}