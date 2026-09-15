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
  sharedSettings = import ../shared/default.nix {
    nixOptions = ./nix-config.nix;
  };
  nixpkgsSettings = sharedSettings.ven.nix.nixpkgs;
  nixpkgsConfig = nixpkgsSettings.config;

  unstableEnabled =
    nixpkgsSettings.unstable.enable
    && (
      (pkgs.stdenv.hostPlatform.isDarwin && nixpkgsSettings.unstable.installOn.darwin)
      || (pkgs.stdenv.hostPlatform.isLinux && nixpkgsSettings.unstable.installOn.linux)
    );

  unstablePkgs =
    if unstableEnabled then
      import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
        config = nixpkgsConfig;
      }
    else throw "ven.nix.nixpkgs.unstable is disabled for this platform.";

  paths = import ./paths.nix { };
in
{
  inherit nixpkgsConfig paths unstablePkgs;
  nixSharedSettings = sharedSettings;

  # ------------------------------------------------------------
  # ------ MODULE PATHS ------ #
  # These paths are values, not imports. Each owning aggregator imports
  # the named module it needs through the appropriate module graph.
  serviceOptions = ./services/default.nix;
  containerBackupOptions = ./backups/container-backup-helper.nix;
  terminalOptions = ./terminal-aliases.nix;
  featureOptions = ./terminal-features.nix;
  cliOptions = ./cli/default.nix;
  envSettingsOptions = ./env-settings;
  espansoOptions = ./package-options/espanso;
  obsidianOptions = ./obsidian/default.nix;
  darwinPackageOptions = import ./package-options { mode = "module"; };
  nixOptions = ./nix-config.nix;
  sharedHomeModule = ../shared/home/default.nix;
}
