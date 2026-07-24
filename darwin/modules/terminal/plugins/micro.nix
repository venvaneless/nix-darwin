# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/micro.nix
# 
# =====================================================================
# MICRO
# 
# Modern and intuitive terminal-based text editor
# =====================================================================

{ pkgs, ... }:

{
  # programs.micro would replace the existing mutable settings.json.
  # Install only the package and keep ~/.config/micro user-owned.
  home.packages = [
    pkgs.micro
  ];

  home.sessionVariables.MICRO_TRUECOLOR = "1";

  programs.fish.shellAliases = {
    # --- nano -> micro
    # Use micro instead of nano.
    nano = "micro";

    # --- smicro -> sudo micro with user config
    # Open files with sudo while keeping your micro config.
    smicro = "sudo micro -config-dir $XDG_CONFIG_HOME/micro";
  };
}
