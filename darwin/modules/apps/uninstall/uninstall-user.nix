# /Users/ven/dotfiles/nix/darwin/modules/apps/uninstall/uninstall-user.nix
#
# APPS: USER-DATA REMOVAL
# ============================================================
# # This file only imports individual uninstallers for
# apps user-daata. It's supposed to be commented out
# most of the time
# ============================================================

{ ... }:
{
  imports = [
    # ./zed-user-data-uninstall.nix
    # ./iterm2-user-data-uninstall.nix
    
    # future user-level uninstallers
  ];
}
