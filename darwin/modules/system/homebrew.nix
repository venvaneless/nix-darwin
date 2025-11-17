# /Users/ven/dotfiles/nix/darwin/modules/system/homebrew.nix

# HOMEBREW
# ============================================================
# Handles declarative system-wide apps and global
# Homebrew configuration.
# ============================================================

{ config, lib, pkgs, ... }:

{
  homebrew = {
    enable = true;

    global.autoUpdate = true;
    onActivation.cleanup = "uninstall";
    
    brews = [
        "nginx"
      ];

    # --- Declarative apps (casks) ---
    casks = [
  { name = "ungoogled-chromium"; args = { appdir = "/Applications"; }; }
];

    # --- Notes ---
    # Do NOT set appdir globally, since you control it per-app.
    # caskArgs.no_quarantine = true;
    # nix-homebrew owns the prefix, so don’t override it.
    # brewPrefix = "/opt/homebrew";
  };
}
