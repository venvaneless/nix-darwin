# shared/terminal/wezterm/plugins/wez-plugins.nix
#
# =====================================================================
# WEZTERM: PLUGIN CONFIGURATION
#
# Nix equivalent of plugins.lua. Imports the embedded Lua modules for
# each enabled WezTerm plugin.
# =====================================================================

{ ... }:

{
  imports = [
    ./wez-helpers.nix
    ./wez-resurrect.nix
    ./wez-sessions.nix
    ./wez-smart_workspace_switcher.nix
    ./tabline.nix
  ];
}
