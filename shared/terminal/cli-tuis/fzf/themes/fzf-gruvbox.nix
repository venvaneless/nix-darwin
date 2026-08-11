# shared/terminal/cli-tuis/fzf/themes/fzf-gruvbox.nix
#
# =====================================================================
# FZF: GRUVBOX THEME
# =====================================================================
#
# The active default. Colours match the Gruvbox values used by WezTerm.
# Select with terminal.fzf.theme = "gruvbox".
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf (
    config.ven.features.terminal.cliTuis.fzf.enable
    && config.terminal.fzf.theme == "gruvbox"
  ) {
    programs.fzf.defaultOptions = [
      "--color=bg:#282828,bg+:#3c3836,fg:#ebdbb2,fg+:#fbf1c7"
      "--color=border:#665c54,header:#fabd2f,hl:#fe8019,hl+:#fabd2f"
      "--color=info:#83a598,marker:#b8bb26,pointer:#fabd2f,prompt:#fabd2f"
      "--color=spinner:#d79921,scrollbar:#665c54,separator:#504945"
    ];
  };
}
