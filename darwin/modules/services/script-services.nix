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
    # Temporarily disabled for debugging:
    ./generations-cleanup.nix
    # ./rsync-all.nix

    # Proof-only module
    # ./ven-proof.nix
  ];
}
