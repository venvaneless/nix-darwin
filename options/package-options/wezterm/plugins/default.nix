# options/package-options/wezterm/plugins/default.nix
#
# =====================================================================
# WEZTERM: PLUGIN MODULES
# =====================================================================
#
# Declares plugin knobs and generates the matching runtime Lua modules.
# Shared values are assigned in shared/terminal/wezterm/wez-plugins.nix.
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