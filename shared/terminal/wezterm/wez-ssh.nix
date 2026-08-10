# shared/terminal/wezterm/wez-ssh.nix
#
# =====================================================================
# WEZTERM: SSH SETTINGS
#
# Nix equivalent of ssh.lua.
#
# The original ssh.lua returns an empty table, and wezterm.lua only
# reads `default_prog` from it. An empty attribute set reproduces that
# behaviour exactly: nothing is merged into the generated config.
#
# To start WezTerm in a remote shell, define `default_prog` here.
# =====================================================================

{ lib, ... }:

{
  # No SSH overrides are active.
}
