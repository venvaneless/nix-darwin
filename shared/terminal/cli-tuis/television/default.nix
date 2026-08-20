# shared/terminal/cli-tuis/television/default.nix
#
# =====================================================================
# TELEVISION
#
# Fast terminal navigation for the active Nix configuration repository.
# Configuration, channel definitions, and generated helpers are split so
# future shared, Linux, or platform-specific channels remain independent.
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

  # ---- SHARED PATHS ---- #
  # The generated configuration location stays home-relative, while the
  # active Nix root comes from shared/terminal/default.nix and therefore
  # follows paths.nix on both Darwin and Linux.
  paths = import ../../../../options/paths.nix { };
  televisionConfig = "${paths.relative.config}/television/config.toml";
  televisionCable = "${paths.relative.config}/television/cable";
  nixConfigDir = config.ven.features.terminal.nixConfigDir;

  # ---- PLATFORM DETECTION ---- #
  # Use the shared platform selector for package defaults and helpers.
  platforms = import ../../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    television.enable
    && ((isDarwin && television.installOn.darwin) || (isLinux && television.installOn.linux));

  # ---- NIX SEARCH EXCLUSIONS ---- #
  # Every Nix channel consumes this one list. Keep generated results out
  # of search so each channel remains focused on maintained source files.
  excludedDirectories = [
    {
      name = ".git";
      gitPathPattern = "(^|/)\\.git(/|$)";
    }
    {
      name = "result";
      gitPathPattern = "(^|/)result(/|$)";
    }
    {
      name = "result-*";
      gitPathPattern = "(^|/)result-[^/]*(/|$)";
    }
    {
      name = ".cache";
      gitPathPattern = "(^|/)\\.cache(/|$)";
    }
  ];

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

  # ---- CHANNEL HELPERS ---- #
  # Generated Fish helpers preserve structured result data while keeping
  # mutable Television state outside the Nix store.
  televisionLib = import ./lib.nix {
    inherit lib pkgs nixConfigDir excludedDirectories isDarwin;
  };

  # ---- CHANNEL DEFINITIONS ---- #
  # Each channel owns its TOML source, preview, action, and keybinding
  # sections. The aggregator is intentionally only an import registry.
  channels = import ./channels {
    inherit televisionLib;
  };
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
      ] ++ lib.optionals isLinux [
        # Linux clipboard actions support both Wayland and X11 sessions.
        pkgs.wl-clipboard
        pkgs.xclip
      ];

      # ---- CORE CONFIGURATION ---- #
      # Television reads its platform-neutral XDG configuration and discovers
      # custom channels declaratively from cable/ through one file registry.
      home.file = {
        "${televisionConfig}".text = import ./config.nix {
          inherit selectedThemeConfig;
        };
      } // lib.mapAttrs' (
        name: text:
        lib.nameValuePair "${televisionCable}/${name}.toml" { inherit text; }
      ) channels;

      # ---- FISH COMMAND WRAPPER ---- #
      # A bare phrase after nix-files becomes Television's initial input.
      # Explicit Television flags and every other channel pass through unchanged.
      programs.fish.functions.tv = {
        description = "Television with Nix file-search input";
        wraps = "tv";
        body = ''
          if test (count $argv) -gt 1; and test "$argv[1]" = "nix-files"
            set -e argv[1]

            if test (count $argv) -gt 0; and not string match -q -- '-*' $argv
              command tv nix-files --input (string join " " -- $argv)
              return $status
            end

            command tv nix-files $argv
            return $status
          end

          command tv $argv
        '';
      };
    })
    (lib.mkIf (cfg.enable && selectedThemeConfig.option != null) {
      # Only the selected theme module is imported and enabled.
      ven.features.terminal.cliTuis.television.${selectedThemeConfig.option}.enable = true;
    })
  ];

  imports = lib.optional (selectedThemeConfig.module != null) selectedThemeConfig.module;
}
