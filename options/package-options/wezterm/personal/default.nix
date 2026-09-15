# options/package-options/wezterm/personal/default.nix
#
# =====================================================================
# WEZTERM: PERSONAL LUA MODULES
# =====================================================================
#
# Declares and renders the Lua modules selected by the shared personal
# WezTerm settings.
# =====================================================================

{ lib, ... }:

{
  imports = [
    ./wez-command_palette.nix
    ./wez-context_palette.nix
    ./wez-nvim_chrome.nix
    ./wez-platform.nix
    ./wez-replace_tab.nix
    ./wez-save_scrollback.nix
  ];

  options.home.shared.terminal.wezterm.personal.modules = lib.mkOption {
    type = lib.types.listOf (
      lib.types.enum [
        "context_palette"
        "save_scrollback"
        "replace_tab"
        "nvim_chrome"
      ]
    );
    default = [ ];
    description = "Personal Lua modules applied to WezTerm in order.";
  };
}
