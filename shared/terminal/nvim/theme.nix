# shared/terminal/nvim/theme.nix

# =====================================================================
# NEOVIM: THEME
#
# Gruvbox colorscheme configuration
#
# Two things are required for the real Gruvbox palette to appear:
#
# - termguicolors, so Neovim sends 24-bit colour instead of falling
#   back to the terminal's 16 ANSI colours
# - medium contrast, which is Gruvbox's canonical #282828 background
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
            -- ---- PALETTE ---- #

            -- "hard", "soft", or "" for the standard medium background.
            -- Soft (#32302f) washes the palette out; medium (#282828) is
            -- the Gruvbox everyone recognises.
            contrast = "",

            -- Recolour the terminal's own 16 colours to match Gruvbox
            -- inside :terminal buffers.
            terminal_colors = true,

            transparent_mode = false,

            -- ---- TEXT STYLES ---- #

            bold = true,
            undercurl = true,
            underline = true,
            strikethrough = true,

            italic = {
              strings = false,
              emphasis = true,
              comments = true,
              operators = false,
              folds = true,
            },

            -- ---- CONTRAST DETAILS ---- #

            -- Keep the selection readable rather than inverting it.
            invert_selection = false,
            invert_signs = false,
            invert_tabline = false,
            inverse = true,

            -- Do not grey out unfocused splits.
            dim_inactive = false,

            -- Per-colour and per-group escape hatches, left empty so the
            -- upstream Gruvbox palette is used verbatim.
            palette_overrides = {},
            overrides = {},
          },
        },

        {
          "AstroNvim/astroui",

          opts = {
            colorscheme = "gruvbox",
          },
        },

        {
          "AstroNvim/astrocore",

          opts = function(_, opts)
            opts.options = opts.options or {}
            opts.options.opt = opts.options.opt or {}

            -- ---- 24-BIT COLOUR ---- #
            -- Without this Neovim ignores the colorscheme's hex values
            -- and renders using WezTerm's 16 ANSI colours instead.
            opts.options.opt.termguicolors = true

            return opts
          end,
        },
      }
    '';
  };
}
