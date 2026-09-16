# shared/default.nix
#
# =====================================================================
# SHARED: HOST AND NIXPKGS SETTINGS
# =====================================================================
#
# The shared knobs for every machine live here. This file deliberately
# contains values only: options/nix-config.nix owns their option types,
# platform selection, validation, and translation into Nix settings.
# =====================================================================

{ ... }: {
  system.shared.nix = {
    # ------------------------------------------------------------
    # Nix daemon and command settings
    # ------------------------------------------------------------
    # Settings for every host; machine-specific settings stay in each host default file
    settings = {
      # Enables the command and flake interfaces used by this repository
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Host dependencies allowed in sandboxed builds
      allowed-impure-host-deps = {
        darwin = [
          "/usr/bin/codesign"
        ];
        linux = [ ];
      };

      # Uses the official Nix binary cache on every host
      substituters = [
        "https://cache.nixos.org"
      ];

      # Trusts the official Nix binary cache signing key
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      # Keeps routine configuration edits from producing dirty-tree warnings
      warn-dirty = false;
    };

    # ------------------------------------------------------------
    # Nixpkgs package sets
    # ------------------------------------------------------------
    nixpkgs = {
      # Applies this policy to the stable package set and, when enabled,
      # to the unstable package set as well
      config = {
        allowUnfree = true;

        permittedInsecurePackages = [
        ];
      };

      unstable = {
        # Makes the unstable package set available to enabled consumers
        enable = true;

        # Enabled on both platforms: VS Code is tracked from unstable
        # everywhere, and unstablePkgs is a throw on a disabled platform
        installOn = {
          darwin = true;
          linux = true;
        };
      };
    };
  };
}
