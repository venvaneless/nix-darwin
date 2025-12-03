# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/homebrew.nix
#
# HOMEBREW (Unified)
# ============================================================
# - Bootstraps Homebrew via nix-homebrew
# - Enables declarative brews & casks
# - Works cleanly with nix-darwin + Determinate
# ============================================================

{ config, lib, pkgs, inputs, nix-homebrew, ... }:

{
  # --- Loads Homebrew
  imports = [
    nix-homebrew.darwinModules.nix-homebrew
  ];

  # --- Configures the nix-homebrew backend
  nix-homebrew = {
    enable = true;
    user = "ven";
    enableRosetta = false;
    autoMigrate = true;
  };

  # --- Homebrew package management ---
  homebrew = {
    enable = true;

    # auto-update when switching
    global.autoUpdate = true;

    # If a package is removed from config, uninstall it
    onActivation.cleanup = "uninstall";

    # ----- Brews -----
    brews = [
      "nginx"
    ];

    # ----- Casks -----
    casks = [
      { name = "ungoogled-chromium"; args = { appdir = "/Applications"; }; }
    ];
  };
}
