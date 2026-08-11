# shared/terminal/wezterm/wez-plugins.nix
#
# =====================================================================
# WEZTERM: PLUGIN CACHE OWNERSHIP
#
# WezTerm plugins are loaded by their HTTPS URLs in the embedded Lua
# modules. WezTerm owns the resulting Git checkouts under its user
# data directory; the Nix store must not replace those checkouts.
# =====================================================================

{ ... }:

{
}
