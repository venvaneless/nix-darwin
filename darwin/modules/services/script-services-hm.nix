# /Users/ven/dotfiles/nix/darwin/modules/services/script-services-hm.nix
#
# HOME-MANAGER: SCRIPT SERVICES AGGREGATOR
# ============================================================
# Bundles all user-level script services (rsync, cleanup, etc.).
# This file replaces the individual imports in home-manager.nix.
# Imported only once in:
#   shared/services/home-manager.nix
# ============================================================

{ ... }:

{
  imports = [
    ./rsync-all-hm.nix
  ];
}
