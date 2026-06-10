# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/micro.nix
# 
# =====================================================================
# MICRO
# 
# Modern and intuitive terminal-based text editor
# =====================================================================

{ pkgs, ... }:

{
  # Micro config already lives at:
  # ~/.config/micro/
  #
  # No xdg.configFile.source is needed here.

  programs.fish.shellAliases = {
    # --- nano -> micro
    # Use micro instead of nano.
    nano = "micro";

    # --- smicro -> sudo micro with user config
    # Open files with sudo while keeping your micro config.
    smicro = "sudo micro -config-dir ~/.config/micro";
  };
}