# shared/terminal/cli-tuis/fastfetch.nix
#
# =====================================================================
# FASTFETCH
#
# Feature-rich and performance oriented,
# neofetch like system information tool
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.fastfetch;

  # Keeps the source configuration intact while resolving the logo through
  # the current host's XDG configuration directory.
  fastfetchConfig =
    builtins.replaceStrings [ "__FASTFETCH_ASCII__" ] [ "${config.xdg.configHome}/fastfetch/ascii.txt" ]
      (builtins.readFile ./fastfetch.jsonc);
in
{
  options.ven.features.terminal.cliTuis.fastfetch.enable =
    lib.mkEnableOption "Fastfetch system information";

  config = lib.mkIf cfg.enable {
    # Install and enable Fastfetch
    programs.fastfetch.enable = true;

    # Store-backed configuration is safe because Fastfetch does not rewrite it.
    xdg.configFile."fastfetch/config.jsonc".text = fastfetchConfig;

    # Keeps the configured ASCII logo available at the portable XDG path.
    xdg.configFile."fastfetch/ascii.txt".source = ./fastfetch-ascii.txt;

    programs.fish.interactiveShellInit = ''
      	# Set Fastfetch config path and marker file
        set -l fastfetch_config "${config.xdg.configHome}/fastfetch/config.jsonc"
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
  };
}
