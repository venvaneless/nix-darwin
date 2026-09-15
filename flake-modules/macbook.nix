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

  # ---- SHARED HOST CONTEXT ---- #
  # Hosts.nix constructs machine-agnostic values once. This Darwin host reads
  # its paths and platform facts from that context without importing options.
  macbookHostContext = config.flake.lib.mkHostContext {
    pkgs = macbookPkgs;
    installTarget = "system";
  };
  inherit (macbookHostContext) paths platforms;

  # ---- DARWIN APPLICATION LINK HELPER ---- #
  # Link behavior is constructed only for the Darwin host, then supplied to
  # package modules through specialArgs rather than imported by those modules.
  macbookSymlinks = import ../options/symlinks.nix {
    lib = inputs.nixpkgs.lib;
    paths = paths;
    pkgs = macbookPkgs;
    platforms = platforms;
  };

  # ---- DARWIN BACKUP HELPERS ---- #
  # Backup implementation is MacBook-only. The helpers are supplied to the
  # Darwin module graph once, so backup files do not import them themselves.
  backupPaths = paths;
  backupExcludeHelper = import ../options/backups/backup-exclude-helper.nix {
    lib = inputs.nixpkgs.lib;
  };
  containersBackupHelper = import ../options/backups/container-backup-helper.nix {
    lib = inputs.nixpkgs.lib;
    pkgs = macbookPkgs;
    paths = backupPaths;
    inherit backupExcludeHelper;
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
      hostContext = macbookHostContext;

      specialArgs = {
        inherit inputs;
        pkgs = macbookPkgs;
        symlinks = macbookSymlinks;
        home-manager = inputs.home-manager;
        nix-homebrew = inputs.nix-homebrew;
        inherit appBackupHelper backupExcludeHelper containersBackupHelper;

      };

      modules = [
        {
          nixpkgs.overlays = [ macbookOverlay ];

        }

        ../darwin/default.nix
      ];
    }
  );
}
