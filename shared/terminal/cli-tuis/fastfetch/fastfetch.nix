# shared/terminal/cli-tuis/fastfetch/fastfetch.nix
#
# =====================================================================
# FASTFETCH
#
# Feature-rich and performance oriented,
# neofetch like system information tool
#
# Every toggle lives in this file. The layout modules hold the module
# list for a machine, the palette files hold nothing but colours, and
# neither is tied to a platform: any layout can use any palette.
#
# The selected layout is the only module that writes fastfetch's single
# config.jsonc. That file exists nowhere in this repository as a file;
# Home Manager renders it from Nix into the store and symlinks it to
# $XDG_CONFIG_HOME/fastfetch/config.jsonc.
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

  # ---- LAYOUT SELECTION ---- #
  # Which module list each platform renders. Both layouts work on either
  # platform, but each one only asks for information its own machine has:
  # "linux" reads the desktop environment, theme, and cursor, and "macos"
  # reads the graphics adapter.
  selectedLayout = {
    darwin = "macos";
    linux = "linux";
  };

  # ---- PALETTE SELECTION ---- #
  # Which colours each platform uses. Palettes are platform independent,
  # so both machines default to gruvbox and either may be changed alone.
  selectedPalette = {
    darwin = "gruvbox";
    linux = "gruvbox";
  };

  # ---- AVAILABLE LAYOUTS ---- #
  # Every layout module is imported; only the selected one writes a file.
  layoutModules = {
    macos = ./fastfetch-macos.nix;
    linux = ./fastfetch-linux.nix;
  };

  # ---- AVAILABLE PALETTES ---- #
  # Plain colour sets rather than modules, so this file can resolve the
  # selection directly and hand it to the layout.
  paletteFiles = {
    gruvbox = ./palettes/gruvbox.nix;
    plasma = ./palettes/plasma.nix;
  };

  # ---- RESOLVED SELECTION ---- #
  layoutForCurrentSystem = if isDarwin then selectedLayout.darwin else selectedLayout.linux;
  paletteForCurrentSystem = if isDarwin then selectedPalette.darwin else selectedPalette.linux;

  checkedLayout =
    if lib.hasAttr layoutForCurrentSystem layoutModules then
      layoutForCurrentSystem
    else
      throw ''
        fastfetch: unknown layout "${layoutForCurrentSystem}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames layoutModules)}
      '';

  checkedPalette =
    if lib.hasAttr paletteForCurrentSystem paletteFiles then
      paletteForCurrentSystem
    else
      throw ''
        fastfetch: unknown palette "${paletteForCurrentSystem}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames paletteFiles)}
      '';
in
{
  options.ven.features.terminal.cliTuis.fastfetch = {
    enable = lib.mkEnableOption "Fastfetch system information";

    layout = lib.mkOption {
      type = lib.types.enum (lib.attrNames layoutModules);
      default = checkedLayout;
      description = "Fastfetch module layout rendered on this machine.";
    };

    palette = lib.mkOption {
      type = lib.types.enum (lib.attrNames paletteFiles);
      default = checkedPalette;
      description = "Fastfetch colour palette used on this machine.";
    };

    colours = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      readOnly = true;
      default = import paletteFiles.${cfg.palette};
      description = "Colours of the selected palette, read by the layout modules.";
    };

    asciiPath = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = "${config.xdg.configHome}/fastfetch/ascii.txt";
      description = "Managed location of the logo the layouts point at.";
    };
  };

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.fastfetch.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      # Install and enable Fastfetch
      programs.fastfetch.enable = true;

      # The logo belongs to fastfetch itself rather than to one layout,
      # so it is declared once here and referenced through asciiPath.
      xdg.configFile."fastfetch/ascii.txt".source = ./ascii.txt;

      programs.fish.interactiveShellInit = ''
        # Set Fastfetch config path and marker file
        set -l fastfetch_config "${config.xdg.configHome}/fastfetch/config.jsonc"

        # TMPDIR is normally unset on Linux, so fall back to /tmp rather
        # than building a marker path at the filesystem root.
        set -l fastfetch_runtime "$TMPDIR"
        if test -z "$fastfetch_runtime"
          set fastfetch_runtime /tmp
        end
        set -l fastfetch_marker "$fastfetch_runtime/fastfetch-shown-$USER"

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

  imports = lib.attrValues layoutModules;
}
