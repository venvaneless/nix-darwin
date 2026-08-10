# shared/terminal/cli-tuis/bat/bat.nix
#
# =====================================================================
# BAT
#
# Syntax-highlighting replacement for cat, used as:
# - The `cat` alias in shared/terminal/aliases/shell-aliases.nix
# - A general file viewer and pager
#
# Installation and settings are managed through Home Manager.
# Themes live in their own files, each with its own toggle:
# - bat-gruvbox.nix   (on)
# - bat-rose-pine.nix (off)
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.bat;
in
{
  options.ven.features.terminal.cliTuis.bat.enable = lib.mkEnableOption "Bat file viewer";

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;

      config = {
        # ---- APPEARANCE ---- #

        # Theme selection is set by bat-gruvbox.nix when its toggle is on.
        # This fallback is bat's own built-in default.
        theme = lib.mkDefault "Monokai Extended";

        # Line numbers, Git change markers, and the file header.
        style = "numbers,changes,header";

        # Wrap long lines at the terminal width.
        wrap = "auto";

        # Keep bat's output plain when it is piped into another command.
        paging = "auto";
      };
    };
  };
}
