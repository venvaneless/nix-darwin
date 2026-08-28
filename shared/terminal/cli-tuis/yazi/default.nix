# shared/terminal/cli-tuis/yazi/default.nix
#
# =====================================================================
# YAZI
#
# Terminal file manager with Fish integration. This module owns Yazi's
# configuration files and plugins through Home Manager.
# Runtime state such as .dds remains outside the Nix store.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.yazi;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Yazi's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.yazi.enable directly.
  yazi = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- PLUGIN TOGGLES ---- #
  # Install controls whether Nix deploys the plugin. Enable controls
  # whether Yazi loads it from init.lua after it has been installed.
  plugins = {
    fullBorder = {
      install = true;
      enable = false;
    };
    yatline = {
      install = true;
      enable = false;
    };
  };

  installedPluginPackages = lib.concatStringsSep "\n\n" (
    (lib.optional plugins.fullBorder.install ''
      [[plugin.deps]]
      use = "yazi-rs/plugins:full-border"
      rev = "5d461d8"
      hash = "7b625412411be411153886894d9acaf"
    '')
    ++ (lib.optional plugins.yatline.install ''
      [[plugin.deps]]
      use = "imsi32/yatline"
      rev = "c5d4b48"
      hash = "e6e98d12b1648d1894c2b560d85eeaa7"
    '')
  );

  enabledPluginSetups = lib.concatStringsSep "\n" (
    (lib.optional (plugins.fullBorder.install && plugins.fullBorder.enable)
      ''require("full-border"):setup()'')
    ++ (lib.optional (plugins.yatline.install && plugins.yatline.enable)
      ''require("yatline"):setup()'')
  );

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    yazi.enable && ((isDarwin && yazi.installOn.darwin) || (isLinux && yazi.installOn.linux));
in
{
  imports =
    (lib.optional plugins.fullBorder.install ./plugins/full-border.nix)
    ++ (lib.optional plugins.yatline.install ./plugins/yatline.nix);

  options.ven.features.terminal.cliTuis.yazi.enable =
    lib.mkEnableOption "Yazi terminal file manager";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.yazi.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      # ---- INSTALLATION ---- #
      programs.yazi = {
        # Install Yazi and integrate its yy shell wrapper with Fish.
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "yy";
      };

      # ---- CORE CONFIGURATION ---- #
      # Each file is rendered at Yazi's normal XDG path and is immutable
      # until this module changes it.
      xdg.configFile = {
        "yazi/init.lua".text = ''
          # Enable installed plugins with the selectors in this module.
          ${enabledPluginSetups}
        '';

        "yazi/package.toml".text = ''
          ${installedPluginPackages}

          [flavor]
          deps = []
        '';

        "yazi/yazi.toml".text = ''
          [flavor]
          dark = "catppuccin-mocha"

          [manager]
          scrolloff = 8
          show_hidden = true
          show_symlink = true
          sort_by = "natural"
          sort_dir_first = true
          sort_reverse = false
          sort_sensitive = false

          [[open.rules]]
          mime = "text/*"
          use = ["edit"]

          [[open.rules]]
          name = "*.md"
          use = ["edit"]

          [[opener.edit]]
          block = true
          desc = "Edit in micro"
          run = "micro \"$@\""

          [[opener.open]]
          desc = "Open"
          run = "open \"$@\""

          [[opener.reveal]]
          desc = "Reveal in Finder"
          orphan = true
          run = "open -R \"$1\""

          [preview]
          tab_size = 2
          wrap = "no"
        '';

        "yazi/theme.toml".text = ''
          [[filetype.rules]]
          fg = "#89b4fa"
          mime = "image/*"

          [[filetype.rules]]
          fg = "#fab387"
          mime = "video/*"

          [[filetype.rules]]
          fg = "#f9e2af"
          mime = "audio/*"

          [[filetype.rules]]
          fg = "#cba6f7"
          mime = "application/*zip"

          [[filetype.rules]]
          fg = "#cba6f7"
          mime = "application/x-tar"

          [[filetype.rules]]
          fg = "#a6e3a1"
          mime = "text/*"

          [manager.border_style]
          fg = "#6c7086"

          [manager.find_keyword]
          bold = true
          fg = "#f5c2e7"

          [manager.find_position]
          bold = true
          fg = "#f9e2af"

          [manager.hovered]
          reversed = true

          [manager.marker_copied]
          bg = "#a6e3a1"
          fg = "#1e1e2e"

          [manager.marker_cut]
          bg = "#f38ba8"
          fg = "#1e1e2e"

          [manager.marker_selected]
          bg = "#89b4fa"
          fg = "#1e1e2e"

          [manager.preview_hovered]
          underline = true

          [manager.tab_active]
          bg = "#89b4fa"
          bold = true
          fg = "#1e1e2e"

          [manager.tab_inactive]
          bg = "#313244"
          fg = "#cdd6f4"

          [notify.title_error]
          fg = "#f38ba8"

          [notify.title_info]
          fg = "#89b4fa"

          [notify.title_warn]
          fg = "#f9e2af"

          [which.cand]
          fg = "#89b4fa"

          [which.desc]
          fg = "#f5c2e7"

          [which.separator_style]
          fg = "#6c7086"
        '';

      };
    })
  ];
}
