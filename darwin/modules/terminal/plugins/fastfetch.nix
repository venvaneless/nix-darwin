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
  # Install and enable Fastfetch
  programs.fastfetch.enable = true;

  
  programs.fish.interactiveShellInit = ''
  	# Set Fastfetch config path and marker file
    set -l fastfetch_config "${config.xdg.configHome}/fastfetch/fastfetch-macos.jsonc"
    set -l fastfetch_marker "$TMPDIR/fastfetch-shown-$USER"

    # Run Fastfetch if it is installed, the config file exists, and the marker file does not exist
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
