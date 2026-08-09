# shared/terminal/cli-tuis/atuin.nix
#
# =====================================================================
# ATUIN
#
# Improved shell history for zsh, bash, fish and nushell
# -----------------------------------------
#
# ---- Keybindings
# -- Start of line
# Ctrl-A
# -- End of line
# Ctrl-E
# -- Delete from cursor back to start
# Ctrl-U
# -- Delete from cursor to end
# Ctrl-K
# -- Delete previous word
# Ctrl-W
# -- Clear screen
# Ctrl-L
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.atuin;
in
{
  options.ven.features.terminal.cliTuis.atuin.enable = lib.mkEnableOption "Atuin shell history";

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      # Install and enable atuin and integrate it with fish shell
      enable = true;
      enableFishIntegration = true;
    };

    programs.fish.shellInit = ''
      # --- ATUIN_NOBIND
      # Prevent Atuin from automatically taking over keybindings.
      set -gx ATUIN_NOBIND true
    '';

    programs.fish.interactiveShellInit = ''
      # --- Ctrl-R
      # Bind Ctrl-R to Atuin search.
      bind \cr _atuin_search
    '';
  };
}
