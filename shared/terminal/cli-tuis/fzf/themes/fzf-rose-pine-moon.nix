# shared/terminal/cli-tuis/fzf/themes/fzf-rose-pine-moon.nix
#
# =====================================================================
# FZF: ROSE PINE MOON THEME
# =====================================================================
#
# This preserves the palette that was previously embedded in fzf.nix.
# Select with terminal.fzf.theme = "rose-pine-moon".
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf (
    config.ven.features.terminal.cliTuis.fzf.enable
    && config.terminal.fzf.theme == "rose-pine-moon"
  ) {
    programs.fzf.defaultOptions = [
      "--color=bg+:#2a273f,bg:#232136,spinner:#f6c177,hl:#ea9a97"
      "--color=fg:#e0def4,header:#ea9a97,info:#9ccfd8,pointer:#c4a7e7"
      "--color=marker:#eb6f92,fg+:#e0def4,prompt:#c4a7e7,hl+:#ea9a97"
    ];
  };
}
