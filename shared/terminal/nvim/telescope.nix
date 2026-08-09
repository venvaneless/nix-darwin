# shared/terminal/nvim/telescope.nix

# =====================================================================
# NEOVIM: TELESCOPE
#
# Reproducible fuzzy finder configuration managed by Lazy and its lockfile.
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/telescope.lua".text = ''
      return {
        {
          "nvim-telescope/telescope.nvim",

          version = "*",

          dependencies = {
            "nvim-lua/plenary.nvim",
          },

          opts = {
            defaults = {
              layout_strategy = "horizontal",
              sorting_strategy = "ascending",

              layout_config = {
                prompt_position = "top",
                preview_width = 0.55,
                width = 0.9,
                height = 0.85,
              },
            },
          },
        },
      }
    '';
  };
}
