# shared/terminal/cli-tuis/fzf/fzf-themes.nix
#
# =====================================================================
# FZF: THEME SELECTOR
# =====================================================================
#
# Select one palette with terminal.fzf.theme, following the same model
# used by terminal.fish.theme. Theme modules only add fzf colour flags;
# all other fzf behaviour remains in fzf.nix.
# =====================================================================

{ lib, ... }:

{
  options.terminal.fzf.theme = lib.mkOption {
    type = lib.types.enum [
      "none"
      "catppuccin"
      "gruvbox"
      "rose-pine-moon"
    ];
    default = "gruvbox";
    description = "Fzf colour palette to use.";
  };

  imports = [
    ./themes/fzf-catppuccin.nix
    ./themes/fzf-gruvbox.nix
    ./themes/fzf-rose-pine-moon.nix
  ];
}
