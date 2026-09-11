# shared/terminal/nvim/themes/nvim-nord.nix
#
# =====================================================================
# NEOVIM THEME: NORD
#
# Every setting this colorscheme takes, as a knob. The plugin's Lua is
# generated from them in options/terminal-features.nix.
# =====================================================================

{ ... }:

{
  ven.features.terminal.nvim.themes.list.nord = {
    plugin = "gbprod/nord.nvim";

    settings = {
      # ---- PALETTE ---- #

      # Nord ships a single palette, so there is no contrast variant to
      # choose. Recolour :terminal buffers to match it.
      terminal_colors = true;

      transparent = false;

      # ---- TEXT STYLES ---- #

      styles = {
        comments = {
          italic = true;
        };
      };
    };
  };
}
