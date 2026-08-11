# shared/terminal/cli-tuis/fzf/themes/fzf-catppuccin.nix
#
# =====================================================================
# FZF: CATPPUCCIN MOCHA THEME
# =====================================================================
#
# Kept as an inactive alternative. Select with
# terminal.fzf.theme = "catppuccin".
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf (
    config.ven.features.terminal.cliTuis.fzf.enable
    && config.terminal.fzf.theme == "catppuccin"
  ) {
    programs.fzf.defaultOptions = [
      "--color=bg:#1e1e2e,bg+:#313244,fg:#cdd6f4,fg+:#f5e0dc"
      "--color=border:#585b70,header:#f5c2e7,hl:#f38ba8,hl+:#fab387"
      "--color=info:#89dceb,marker:#a6e3a1,pointer:#cba6f7,prompt:#cba6f7"
      "--color=spinner:#f9e2af,scrollbar:#585b70,separator:#45475a"
    ];
  };
}
