# shared/terminal/nvim/theme.nix

# =====================================================================
# NEOVIM: THEME
#
# Gruvbox colorscheme configuration
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/theme.lua".text = ''
      return {
        {
          "ellisonleao/gruvbox.nvim",

          priority = 1000,

          opts = {
            terminal_colors = true,

            contrast = "hard",

            transparent_mode = false,
          },
        },

        {
          "AstroNvim/astroui",

          opts = {
            colorscheme = "gruvbox",
          },
        },
      }
    '';
  };
}
