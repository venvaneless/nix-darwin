# shared/terminal/nvim/theme.nix

# =====================================================================
# NEOVIM: THEME SELECTION
#
# Which colorscheme every machine uses, and each theme's own values.
# Their schema and generated Lua live in options/cli/nvim/themes.
#
# ** A machine sets its own in its home file:
# **
# **   home.shared.terminal.nvim.theme = "nord";
# =====================================================================

{ ... }:

{
  imports = [
    ./themes/gruvbox.nix
    ./themes/nord.nix
  ];

  home.shared.terminal.nvim.theme = "gruvbox";
}
