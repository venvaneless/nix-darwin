# shared/terminal/commands/default.nix
#
# =====================================================================
# FISH: PORTABLE COMMANDS
# =====================================================================

{ lib, ... }:

{
  imports = [
    ./chmod.nix
    ./downloads.nix
  ];

  # downloads.nix deliberately owns its implementation and option.
  # Keep its existing default here without changing that module.
  config = {
    home.shared.terminal.fish.downloads.enable = lib.mkDefault true;

  };
}
