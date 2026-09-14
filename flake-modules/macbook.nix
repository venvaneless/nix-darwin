# flake-modules/macbook.nix
#
# =====================================================================
# DARWIN HOST: MACBOOK
#
# Defines the macbook-specific nix-darwin configuration and connects it
# to the flake-parts package outputs for the matching platform.
# =====================================================================

{
  config,
  inputs,
  withSystem,
  ...
}:

let
  system = "aarch64-darwin";

  # ---- SHARED NIXPKGS POLICY ---- #
  # Host construction exposes the common policy; MacBook only adds overlays.
  nixpkgsConfig = config.flake.lib.nixpkgsConfig;

  # Load the list of overlays from darwin/overlays.
  macbookOverlays = import ../darwin/overlays;

  macbookOverlay = inputs.nixpkgs.lib.composeManyExtensions macbookOverlays;

  # Provide the fully configured package set as a module special argument.
  # This keeps shared package-list helpers independent of the module fixpoint.
  macbookPkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
    overlays = [ macbookOverlay ];
  };

  # ---- DARWIN BACKUP HELPERS ---- #
  # Backup implementation is MacBook-only. The helpers are supplied to the
  # Darwin module graph once, so backup files do not import them themselves.
  backupPaths = import ../options/paths.nix {};
  backupExcludeHelper = import ../options/backups/backup-exclude-helper.nix {
    lib = inputs.nixpkgs.lib;
  };
  appBackupHelper = import ../options/backups/app-backup-helper.nix {
    lib = inputs.nixpkgs.lib;
    pkgs = macbookPkgs;
    paths = backupPaths;
    inherit backupExcludeHelper;
  };

in
{
  # =====================================================================
  # NIXPKGS OVERLAYS (modular, imported from darwin/overlays/)
  # =====================================================================
  flake.overlays.macbook = macbookOverlay;

  # =====================================================================
  # DARWIN: MAIN SYSTEM
  # =====================================================================
  flake.darwinConfigurations.macbook = withSystem system (
    { ... }:
    config.flake.lib.mkDarwinHost {
      inherit system;

      specialArgs = {
        inherit inputs;
        pkgs = macbookPkgs;
        home-manager = inputs.home-manager;
        nix-homebrew = inputs.nix-homebrew;
        inherit appBackupHelper backupExcludeHelper;

      };

      modules = [
        {
          nixpkgs.overlays = [ macbookOverlay ];

        }

        # Darwin-only backup option declarations.
        ../options/backups/container-backup-helper.nix
        appBackupHelper.settingsModule

        ../darwin/default.nix
      ];
    }
  );
}
