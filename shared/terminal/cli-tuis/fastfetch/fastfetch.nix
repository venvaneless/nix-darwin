# shared/terminal/cli-tuis/fastfetch/fastfetch.nix
#
# =====================================================================
# FASTFETCH
#
# Feature-rich and performance oriented,
# neofetch like system information tool
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.fastfetch;

  # ---- PLATFORM DETECTION ---- #
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Fastfetch's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.fastfetch.enable directly.
  fastfetch = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  enabledForCurrentSystem =
    fastfetch.enable
    && ((isDarwin && fastfetch.installOn.darwin) || (isLinux && fastfetch.installOn.linux));

  # ---- FASTFETCH PROFILE TOGGLES ---- #
  # Enable one profile for each platform. The enabled profile is the only
  # module that writes Fastfetch's single config.jsonc file.
  profiles = {
    gruvbox = {
      enable = true;
      installOn = {
        darwin = true;
        linux = false;
      };
    };
    linuxPalette = {
      enable = true;
      installOn = {
        darwin = false;
        linux = true;
      };
    };
  };

  enabledProfiles = lib.filterAttrs (_: profile: profile.enable) cfg.profiles;
in
{
  options.ven.features.terminal.cliTuis.fastfetch.enable =
    lib.mkEnableOption "Fastfetch system information";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.fastfetch.enable = lib.mkDefault enabledForCurrentSystem;

      ven.features.terminal.cliTuis.fastfetch.profiles = lib.mapAttrs (
        _: profile:
        {
          enable = lib.mkDefault (
            profile.enable
            && ((isDarwin && profile.installOn.darwin) || (isLinux && profile.installOn.linux))
          );
        }
      ) profiles;
    }
    (lib.mkIf cfg.enable {
      # Install and enable Fastfetch
      programs.fastfetch.enable = true;

    assertions = [
      {
        assertion = lib.length (lib.attrNames enabledProfiles) <= 1;
        message = ''
          fastfetch: only one profile may be enabled for the current platform.
          Adjust the enable values in shared/terminal/cli-tuis/fastfetch/fastfetch.nix.
        '';
      }
    ];

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
    })
  ];

  imports = [
    ./fastfetch-mac.nix
    ./fastfetch-linux.nix
  ];
}
