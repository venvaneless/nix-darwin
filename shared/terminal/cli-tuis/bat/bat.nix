# shared/terminal/cli-tuis/bat/bat.nix
#
# =====================================================================
# BAT
#
# Syntax-highlighting replacement for cat, used as:
# - The `cat` alias in shared/terminal/aliases/shell-aliases.nix
# - A general file viewer and pager
#
# Installation and settings are managed through Home Manager.
# Themes live in their own files. Select one directly below; bat imports
# and enables only that one module.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ven.features.terminal.cliTuis.bat;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Bat's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.bat.enable directly.
  bat = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    bat.enable && ((isDarwin && bat.installOn.darwin) || (isLinux && bat.installOn.linux));

  # ---- THEME SELECTION ---- #
  # Change this value to select a different saved bat theme.
  selectedTheme = "gruvboxDark";

  # ---- AVAILABLE THEMES ---- #
  # Each custom theme remains separate, but only selectedTheme is imported.
  themeModules = {
    default = {
      module = null;
      option = null;
    };
    gruvboxDark = {
      module = ./bat-gruvbox.nix;
      option = "gruvbox";
    };
    rosePine = {
      module = ./bat-rose-pine.nix;
      option = "rosePine";
    };
  };

  selectedThemeConfig =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        bat: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';
in
{
  options.ven.features.terminal.cliTuis.bat.enable = lib.mkEnableOption "Bat file viewer";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.bat.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      programs.bat = {
        enable = true;

        config = {
          # ---- APPEARANCE ---- #

          # The selected theme module overrides this built-in fallback.
          theme = lib.mkDefault "Monokai Extended";

          # Line numbers, Git change markers, and the file header.
          style = "numbers,changes,header";

          # Wrap long lines at the terminal width.
          wrap = "auto";

          # Keep bat's output plain when it is piped into another command.
          paging = "auto";
        };
      };

      # Home Manager always rebuilds bat's cache. Keep the cache current while
      # silencing its informational messages about empty custom-theme folders.
      home.activation.batCache = lib.mkForce (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          (
            export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
            cd "${pkgs.emptyDirectory}"
            run ${lib.getExe config.programs.bat.package} cache --build >/dev/null 2>&1
          )
        ''
      );
    })
    (lib.mkIf (cfg.enable && selectedThemeConfig.option != null) {
      # Only the selected theme module is imported and enabled.
      ven.features.terminal.cliTuis.bat.${selectedThemeConfig.option}.enable = true;
    })
  ];

  imports = lib.optional (selectedThemeConfig.module != null) selectedThemeConfig.module;
}
