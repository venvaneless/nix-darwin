# shared/terminal/commands/chmod.nix
#
# =====================================================================
# QUICK ACTIONS: XSCRIPT
#
# ---- xscript -> chmod script file or scripts in folder ---- #
# Makes one script executable, or all scripts in a folder
# =====================================================================

{ config, lib, pkgs, ... }:

let
  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;

  # Makes selected scripts executable.
  installOn = {
    darwin = true;
    linux = true;
  };

  enabledForCurrentSystem =
    (isDarwin && installOn.darwin) || (isLinux && installOn.linux);
in
{
  config = lib.mkIf enabledForCurrentSystem {
    programs.fish.functions.xscript = ''
      if test (count $argv) -eq 0
        echo "Usage: xscript <file> [file ...]"
        return 1
      end

      chmod +x $argv
    '';
  };
}
