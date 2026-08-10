# shared/terminal/wezterm/wez-lua.nix
#
# =====================================================================
# WEZTERM: RUNTIME LUA MODULES
#
# Deploys the Lua modules that cannot be expressed as Nix data,
# because they rely on closures, callbacks or the WezTerm event API.
#
# The files live in this repository next to the Nix modules and are
# symlinked into the WezTerm configuration directory, so nothing has
# to be created or edited under ~/.config/wezterm by hand.
#
# Each entry links a whole directory, which means a new .lua file is
# deployed by the next rebuild without editing this module.
#
# The modules are activated from extraConfig in default.nix.
# =====================================================================

{
  config,
  lib,
  ...
}:

let
  cfg = config.ven.features.terminal.wezterm;
in

{
  config = lib.mkIf cfg.enable {
    xdg.configFile = {
      # ---- Plugin wrappers
      # Thin modules around the pinned upstream plugins that are
      # fetched by wez-plugins.nix.
      "wezterm/plugins".source = ./plugins;

      # ---- Personal modules
      # Standalone behaviour written for this configuration.
      "wezterm/personal".source = ./personal;

      # ---- Overlays
      # The quick commands entry added to the command palette.
      "wezterm/overlays".source = ./overlays;

      # ---- Catppuccin templates
      # Always deployed, only loaded when a toggle in
      # wez-catppuccin.nix is enabled.
      "wezterm/catppuccin-config".source = ./catppuccin-config;

      "wezterm/themes.lua".source = ./themes.lua;

      # ---- Theme templates
      # Alternative colour schemes. Always deployed, only loaded when
      # a toggle in wez-themes.nix is enabled.
      "wezterm/themes".source = ./themes;
    };
  };
}
