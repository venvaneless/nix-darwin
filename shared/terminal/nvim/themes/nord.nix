# shared/terminal/nvim/themes/nord.nix
#
# =====================================================================
# NEOVIM THEME: NORD
#
# Every setting this colorscheme takes, as a knob. The plugin's Lua is
# generated from them in options/cli/nvim/themes/helper.nix.
# =====================================================================

{ ... }:

{
  config.home.shared.terminal.nvim.themes.nord = {
    name = "nord";
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
