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
  # The MacBook starts from the portable policy, then applies its own overlay
  # only while constructing this machine's package set.
  macbookNixpkgsConfig = config.flake.lib.sharedNixpkgsConfig;

  # Load the list of overlays from darwin/overlays.
  macbookOverlays = import ../darwin/overlays;

  macbookOverlay = inputs.nixpkgs.lib.composeManyExtensions macbookOverlays;

  # Provide the fully configured package set as a module special argument.
  # This keeps shared package-list helpers independent of the module fixpoint.
  macbookPkgs = import inputs.nixpkgs {
    inherit system;
    config = macbookNixpkgsConfig;
    overlays = [ macbookOverlay ];
  };

  # ---- DARWIN-ONLY OPTION CONTEXT ---- #
  # Obsidian's commands are not part of the portable host context. Read its
  # option-module path from the shared plain options context, then wire it
  # only into this Darwin host.
  sharedOptions = import ../options {
    inherit inputs;
    pkgs = macbookPkgs;
  };
  inherit (sharedOptions) containerBackupOptions obsidianOptions paths;

  # ---- DARWIN BACKUP HELPERS ---- #
  # Backup implementation is MacBook-only. The helpers are supplied to the
  # Darwin module graph once, so backup files do not import them themselves.
  backupPaths = paths;
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

        # Obsidian commands are enabled only for this Darwin host, while the
        # module itself remains a Home Manager module.
        {
          home-manager.sharedModules = [ obsidianOptions ];
        }

        # Darwin-only backup option declarations.
        containerBackupOptions
        appBackupHelper.settingsModule

        ../darwin/default.nix
      ];
    }
  );
}
