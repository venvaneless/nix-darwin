# shared/terminal/commands/chmod.nix
#
# =====================================================================
# QUICK ACTIONS: XSCRIPT
#
# ---- xscript -> chmod script file or scripts in folder ---- #
# Makes one script executable, or all scripts in a folder
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.fish.commands;
in
{
  config = lib.mkIf cfg.enable {
    programs.fish.functions.xscript = ''
      if test (count $argv) -eq 0
        echo "Usage: xscript <file> [file ...]"
        return 1
      end

      chmod +x $argv
    '';
  };
}
