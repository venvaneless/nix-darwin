# /Users/ven/dotfiles/nix/darwin/index.nix
# VEN_DEBUG_MARKER_FINAL

# DARWIN: MAIN MODULE
# =========================
# This file defines the full macOS (nix-darwin) + Home Manager configuration
# for Ven’s MacBook system.

# ----- System-wide configuration -----
# Everything below runs under nix-darwin context and may require root
# (via `sudo -E darwin-rebuild switch`). These handle system paths,
# Homebrew, launchd services, and Applications folder installs.

{ config, pkgs, lib, ... }:

  {
    system.primaryUser = "ven";

    imports = [
      # --- Shared cross-platform Home Manager integration ---
      ../shared/services/home-manager.nix

      # === System-level modules ===
      ./modules/system/base.nix
      ./modules/system/homebrew.nix
      ./modules/terminal/shell.nix
      ./modules/services/nix-homebrew.nix
      ./modules/services/script-services.nix

      # --- Installing apps ---
      ./modules/apps/apps.nix
      # ./modules/apps/uninstall/uninstall.nix
    ];
  }
