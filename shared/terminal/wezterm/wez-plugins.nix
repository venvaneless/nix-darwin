# shared/terminal/wezterm/wez-plugins.nix
#
# =====================================================================
# WEZTERM: PINNED PLUGINS
#
# WezTerm normally clones every plugin from GitHub the first time
# wezterm.plugin.require() runs, which needs network access and is not
# reproducible. This module takes the sources from the flake inputs
# instead and places them where WezTerm expects to find its clones, so
# the runtime never reaches the network.
#
# Because the plugins are flake inputs, they are pinned in flake.lock
# and updated by the normal workflow:
#
#   nix flake update                    update everything
#   nix flake update wezterm-tabline    update one plugin
#
# There are no revisions or hashes to maintain in this file.
#
# WezTerm derives the cache directory name from the plugin URL by
# escaping the punctuation:
#
#   ":"  ->  "sCs"
#   "/"  ->  "sZs"
#   "."  ->  "sDs"
#
# so that https://github.com/MLFlexer/resurrect.wezterm becomes
# httpssCssZssZsgithubsDscomsZsMLFlexersZsresurrectsDswezterm
#
# Hyphens and underscores are left untouched.
# =====================================================================

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.ven.features.terminal.wezterm;

  # ------------------------------------------------------------
  # ------ PLUGIN CACHE LOCATION ------ #
  #
  # WezTerm stores plugins in its platform data directory, which is
  # not the same place on macOS and Linux.
  # ------------------------------------------------------------

  pluginRoot =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/wezterm/plugins"
    else
      ".local/share/wezterm/plugins";

  # ------------------------------------------------------------
  # ------ URL MANGLING ------ #
  #
  # Reproduces the directory naming scheme used by WezTerm.
  # ------------------------------------------------------------

  mangleUrl =
    url:
    builtins.replaceStrings
      [ ":" "/" "." ]
      [ "sCs" "sZs" "sDs" ]
      url;

  # ------------------------------------------------------------
  # ------ PLUGIN DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the plugin is deployed at all.
  #
  # url:
  #   The URL passed to wezterm.plugin.require() in the matching
  #   wrapper under plugins/. It determines the cache directory name,
  #   so it must match the wrapper exactly.
  #
  # source:
  #   The flake input holding the plugin source.
  # ------------------------------------------------------------

  weztermPlugins = {
    # ---- Resurrect
    # Saves and restores workspace, window and tab state.
    resurrect = {
      enable = true;
      url = "https://github.com/MLFlexer/resurrect.wezterm";
      source = inputs.wezterm-resurrect;
    };

    # ---- Tabline
    # Renders the configurable status and tab bar.
    tabline = {
      enable = true;
      url = "https://github.com/michaelbrusegard/tabline.wez";
      source = inputs.wezterm-tabline;
    };

    # ---- Sessions
    # Persists and reloads named sessions.
    sessions = {
      enable = true;
      url = "https://github.com/abidibo/wezterm-sessions";
      source = inputs.wezterm-sessions;
    };

    # ---- Smart workspace switcher
    # Fuzzy switching between project workspaces.
    smartWorkspaceSwitcher = {
      enable = true;
      url = "https://github.com/MLFlexer/smart_workspace_switcher.wezterm";
      source = inputs.wezterm-smart-workspace-switcher;
    };
  };

  # ------------------------------------------------------------
  # ------ PLUGIN DEPLOYMENT ------ #
  #
  # Each enabled plugin becomes one home.file entry pointing at its
  # flake input, keyed by the mangled URL that WezTerm looks up.
  # ------------------------------------------------------------

  enabledPlugins =
    lib.filterAttrs
      (_: weztermPlugin: weztermPlugin.enable)
      weztermPlugins;

  pluginFileEntry =
    weztermPlugin:

    lib.nameValuePair
      "${pluginRoot}/${mangleUrl weztermPlugin.url}"
      { source = weztermPlugin.source; };

  pluginFiles =
    lib.mapAttrs'
      (_: pluginFileEntry)
      enabledPlugins;
in

{
  config = lib.mkIf cfg.enable {
    home.file = pluginFiles;
  };
}
