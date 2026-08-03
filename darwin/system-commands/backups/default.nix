# darwin/system-commands/backups/default.nix
#
# =====================================================================
# CONTAINER BACKUPS
#
# Each container backup is independently enabled. Set runOnRebuild to
# true to run every enabled backup during darwin-rebuild switch. Each
# individual backup can still opt out with its runOnRebuild option.
# =====================================================================

{ lib, ... }:

{
  options.services.containerBackups.runOnRebuild = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Run enabled container backups during darwin-rebuild activation.";
  };

  config.services.containerBackups = {
    archivebox.enable = true;
    browsertrix.enable = true;
    vaultwarden.enable = true;
    wallabag.enable = true;
  };

  imports = [
    ./archivebox.nix
    ./browsertrix.nix
    ./obsidian-library.nix
    ./vaultwarden.nix
    ./wallabag.nix
  ];
}
