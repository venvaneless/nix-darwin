# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/fastfetch.nix
#
# =====================================================================
# FASTFETCH
# 
# Feature-rich and performance oriented,
# neofetch like system information tool
# =====================================================================

{ config, ... }:

{
  # Installs Fastfetch without replacing the existing JSONC configuration.
  programs.fastfetch.enable = true;

  programs.fish.interactiveShellInit = ''
    set -l fastfetch_config "${config.xdg.configHome}/fastfetch/fastfetch-macos.jsonc"
    set -l fastfetch_marker "$TMPDIR/fastfetch-shown-$USER"

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
