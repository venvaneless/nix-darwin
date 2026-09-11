# shared/terminal/nvim/theme.nix

# =====================================================================
# NEOVIM: THEMES
#
# Which colorscheme every machine uses. Each one's settings live in its
# own file under ./themes, the same way WezTerm's do, and the Lua is
# generated from them in options/terminal-features.nix.
#
# Adding one: write ./themes/nvim-<name>.nix and import it below.
#
# ** default is what every machine uses. A machine sets its own in its
# ** home file:
# **
# **   ven.features.terminal.nvim.themes.default = "nord";
# =====================================================================

{ ... }:

{
  imports = [
    ./themes/nvim-gruvbox.nix
    ./themes/nvim-nord.nix
  ];

  ven.features.terminal.nvim.themes.default = "gruvbox";
}
