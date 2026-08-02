# /Users/ven/.config/nix/nix-config/darwin/modules/apps/apps.nix
#
# =====================================================================
# LOAD APPS
# 
# This file imports individual installers for apps
# and enables selected user-facing programs
# =====================================================================

{ ... }:

{
  imports = [
    ./helium-browser.nix
    ./keyboardSwitcher.nix
    ./obsidian.nix
    # ./paste.nix
    ./raycast.nix
    # ./vscode.nix
    ./wezterm.nix
    ./zed.nix
  ];
}
