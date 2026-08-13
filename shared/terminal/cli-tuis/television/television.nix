# shared/terminal/cli-tuis/television/television.nix
#
# =====================================================================
# TELEVISION
#
# Fast terminal fuzzy finder for files, text, Git repositories,
# environment variables, and custom channels.
#
# The selected theme is kept in its own module so the Television settings
# and Gruvbox palette remain independently readable and maintainable.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.television;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Television's default per platform. Hosts
  # can still override ven.features.terminal.cliTuis.television.enable directly.
  television = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from paths.nix ---- #
  # Keep Television's XDG configuration location derived from the one
  # shared home-relative config path rather than repeating .config.
  paths = import ../../../../options/paths.nix { };
  televisionConfig = "${paths.relative.config}/television/config.toml";

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    television.enable
    && ((isDarwin && television.installOn.darwin) || (isLinux && television.installOn.linux));

  # ---- THEME SELECTION ---- #
  # Change this value to select a different saved Television theme.
  selectedTheme = "gruvbox";

  # ---- AVAILABLE THEMES ---- #
  # The Default selection leaves Television on its built-in palette.
  themeModules = {
    default = {
      module = null;
      option = null;
      name = "television";
    };
    gruvbox = {
      module = ./themes/gruvbox.nix;
      option = "gruvbox";
      name = "ven-gruvbox";
    };
  };

  selectedThemeConfig =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        television: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';
in
{
  options.ven.features.terminal.cliTuis.television.enable = lib.mkEnableOption "Television fuzzy finder";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.television.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      home.packages = [
        pkgs.television
      ];

      home.file."${televisionConfig}".text = ''
        # Managed by shared/terminal/cli-tuis/television/television.nix.
        # The active palette is supplied by the selected theme module.

        [ui]
        theme = "${selectedThemeConfig.name}"
      '';
    })
    (lib.mkIf (cfg.enable && selectedThemeConfig.option != null) {
      # Only the selected theme module is imported and enabled.
      ven.features.terminal.cliTuis.television.${selectedThemeConfig.option}.enable = true;
    })
  ];

  imports = lib.optional (selectedThemeConfig.module != null) selectedThemeConfig.module;
}
