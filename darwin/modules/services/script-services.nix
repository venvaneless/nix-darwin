# /Users/ven/dotfiles/nix/darwin/modules/services/script-services.nix
#
# CLEANUP SERVICES AGGREGATOR
# ============================================================
# Loads all maintenance/cleanup modules.
# Imported once in darwin/index.nix.
# ============================================================

{ ... }:

{
  imports = [
    ./generations-cleanup.nix
    ./rsync-all.nix
  ];
}
