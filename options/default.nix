# options/default.nix
#
# =====================================================================
# OPTIONS: SHARED OPTION CONTEXT
#
# Provides plain pre-fixpoint values and named module paths for host
# composition. It does not declare options or load those modules.
# Nix defaults and Nixpkgs option logic live in options/nix-config.nix.
# =====================================================================
{ inputs ? null, pkgs ? null, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED HOST VALUES ------ #
  # Read shared values before a module fixpoint exists. Host constructors
  # pass the returned context to the system or Home Manager module graph.
  sharedSettings = import ../shared/default.nix { };
  nixpkgsSettings = sharedSettings.system.shared.nix.nixpkgs;
  nixpkgsConfig = nixpkgsSettings.config;

  # Only read when unstablePkgs is used, so hosts that call this without
  # pkgs never evaluate it.
  platforms = import ./platforms.nix { inherit pkgs; };

  unstableEnabled = platforms.enabledForCurrentPlatform nixpkgsSettings.unstable;

  unstablePkgs =
    if unstableEnabled then
      import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
        config = nixpkgsConfig;
      }
    else throw "system.shared.nix.nixpkgs.unstable is disabled for this platform.";

  paths = import ./paths.nix { };
in
{
  inherit nixpkgsConfig paths unstablePkgs;

  # ------------------------------------------------------------
  # ------ MODULE PATHS ------ #
  # These paths are values, not imports. Each owning aggregator imports
  # the named module it needs through the appropriate module graph.
  serviceOptions = ./services/default.nix;
  settingsOptions = ./settings;
  containerBackupOptions = ./backups/container-backup-helper.nix;
  terminalOptions = ./cli/aliases.nix;
  weztermOptions = ./package-options/wezterm;
  cliOptions = ./cli/default.nix;
  envSettingsOptions = ./env-settings;
  espansoOptions = ./package-options/espanso;
  vscodeOptions = ./package-options/vscode.nix;
  qbittorrentOptions = ./package-options/qbittorrent;
  obsidianOptions = ./obsidian/default.nix;
  darwinPackageOptions = import ./package-options { mode = "module"; };
  sharedPackageOptions = import ./package-options { mode = "shared"; };
  # Shared Nix settings: option logic and the values every host uses.
  nixSharedSettings = {
    imports = [
      ./nix-config.nix
      ../shared/default.nix
    ];
  };
  sharedHomeModule = ../shared/home/default.nix;
}
