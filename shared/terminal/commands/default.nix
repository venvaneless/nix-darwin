# shared/terminal/commands/default.nix
#
# =====================================================================
# FISH: PORTABLE COMMANDS
# =====================================================================

{ config, lib, ... }:

{
  imports = [
    ./chmod.nix
    ./files-folders.nix
    ./downloads.nix
  ];

  # downloads.nix deliberately owns its implementation and option.
  # Keep its existing default here without changing that module.
  config = {
    ven.features.terminal.fish.downloads.enable = lib.mkDefault true;
  };
}
