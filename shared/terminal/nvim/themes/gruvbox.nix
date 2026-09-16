# shared/terminal/nvim/themes/gruvbox.nix
#
# =====================================================================
# NEOVIM THEME: GRUVBOX
#
# Every setting this colorscheme takes, as a knob. The plugin's Lua is
# generated from them in options/cli/nvim/themes/helper.nix.
#
# ** Choosing it is shared/terminal/nvim/theme.nix, or a machine's own
# ** home file.
# =====================================================================

{ ... }:

{
  config.home.shared.terminal.nvim.themes.gruvbox = {
    name = "gruvbox";
    plugin = "ellisonleao/gruvbox.nvim";

    settings = {
      # ---- PALETTE ---- #

      # "hard", "soft", or "" for the standard medium background.
      # Soft (#32302f) washes the palette out; medium (#282828) is
      # the Gruvbox everyone recognises.
      contrast = "";

      # Recolour the terminal's own 16 colours to match Gruvbox
      # inside :terminal buffers.
      terminal_colors = true;

      transparent_mode = false;

      # ---- TEXT STYLES ---- #

      bold = true;
      undercurl = true;
      underline = true;
      strikethrough = true;

      italic = {
        strings = false;
        emphasis = true;
        comments = true;
        operators = false;
        folds = true;
      };

      # ---- CONTRAST DETAILS ---- #

      # Keep the selection readable rather than inverting it.
      invert_selection = false;
      invert_signs = false;
      invert_tabline = false;
      inverse = true;

      # Do not grey out unfocused splits.
      dim_inactive = false;

      # Per-colour and per-group escape hatches, left empty so the
      # upstream Gruvbox palette is used verbatim.
      palette_overrides = { };
      overrides = { };
    };
  };
}
