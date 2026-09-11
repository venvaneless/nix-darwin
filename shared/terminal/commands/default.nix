# shared/terminal/commands/default.nix
#
# =====================================================================
# FISH: PORTABLE COMMANDS
# =====================================================================

{ config, lib, ... }:

{
  imports = [
    ./chmod.nix
    ./downloads.nix
    ./obsidian-download-core.nix
    ./obsidian-library-core.nix
    ./obsidian.nix
  ];

  # downloads.nix deliberately owns its implementation and option.
  # Keep its existing default here without changing that module.
  config = {
    ven.features.terminal.fish.downloads.enable = lib.mkDefault true;

    # The new command starts with the same available behavior as its fallbacks.
    # Individual modes can be disabled without changing those fallback commands.
    #
    # ** OFF while the portable rewrite is in progress. The three modules
    # ** it gates -- obsidian-download-core.nix, obsidian-library-core.nix
    # ** and obsidian.nix -- are each wrapped in lib.mkIf on this flag, so
    # ** nothing in them is evaluated while it is false and a half-finished
    # ** expression cannot break a rebuild.
    # **
    # ** The Darwin commands they will eventually replace are untouched and
    # ** stay available: gitdll and obsidian-missing from
    # ** shared/terminal/commands/downloads.nix, which has its own
    # ** ven.features.terminal.fish.downloads.enable flag, and
    # ** obsidian-library from darwin/system-commands/backups/.
    # **
    # ** Set this back to true when the rewrite is ready.
    ven.features.obsidian = {
      enable = lib.mkDefault false;
      modes = {
        library.enable = lib.mkDefault true;
        plugins.enable = lib.mkDefault true;
        themes.enable = lib.mkDefault true;
        missing.enable = lib.mkDefault true;
      };
    };
  };
}
