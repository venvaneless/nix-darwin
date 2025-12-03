# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/uninstall/uninstall.nix
#
# APPS - UNINSTALL
# ============================================================
# This file only imports individual uninstallers for apps
# installed through Nix.
# ============================================================
#
{ ... }:
{
  imports = [
    # ./chromium-uninstall.nix
    # ./iterm-uninstall.nix
    # ./zed-uninstall.nix
  ];
}
