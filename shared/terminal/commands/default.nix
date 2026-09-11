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
    ./obsidian.nix
  ];

  # downloads.nix deliberately owns its implementation and option.
  # Keep its existing default here without changing that module.
  config = {
    ven.features.terminal.fish.downloads.enable = lib.mkDefault true;

  };
}
