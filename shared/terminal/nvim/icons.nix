# shared/terminal/nvim/icons.nix

# =====================================================================
# NEOVIM: ICONS
#
# Shared file and language icons for Neovim UI plugins
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/icons.lua".text = ''
      return {
        {
          "nvim-tree/nvim-web-devicons",

          lazy = true,

          opts = {},
        },
      }
    '';
  };
}
